package main

import "flag"
import "fmt"
import "os"
import "io/ioutil"
import "gopkg.in/yaml.v2"

type ProjectPubConfig struct {
    DeployTo       string `yaml:"deploy_to"`
    GitRepo        string `yaml:"git_repo"`
    BeforeCmd      string `yaml:"before_cmd"`
    AfterCmd       string `yaml:"after_cmd"`
    RelatedProject string `yaml:"related_project"`
}

func main() {
    vpcmPath    := flag.String("i", "", "vpcm root path")
    env         := flag.String("e", "", "environment")
    projectName := flag.String("p", "", "project name")
    cmdType     := flag.String("s", "", "before/after/deploy/related_project")
    
    flag.Parse()

    if *vpcmPath == "" || *projectName == "" || *cmdType=="" || *env=="" {
        fmt.Println("invalid arguments")
        return
    }

    configFile := fmt.Sprintf("%s/%s/%s/pub_config.yml", *vpcmPath, *env, *projectName)
    fileContent, err := ioutil.ReadFile(configFile)
    if err!=nil {
        panic(err)
    }

    var config ProjectPubConfig
    yaml.Unmarshal(fileContent, &config)

    switch(*cmdType) {
        case "before":
            fmt.Printf(config.BeforeCmd)
        case "after":
            fmt.Printf(config.AfterCmd)
        case "deploy":
            fmt.Printf(config.DeployTo)
        case "related_project":
            fmt.Printf(config.RelatedProject)
        default:
        os.Exit(1)
    }
}

