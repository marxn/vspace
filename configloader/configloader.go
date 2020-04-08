package main

import "flag"
import "fmt"
import "os"
import "io/ioutil"
import "gopkg.in/yaml.v2"

type ProjectPubConfig struct {
    ProjectName    string `yaml:"project_name"`
    DeployTo       string `yaml:"deploy_to"`
    BeforeCmd      string `yaml:"before_cmd"`
    AfterCmd       string `yaml:"after_cmd"`
    RelatedProject string `yaml:"related_plan"`
    ServiceGroup   string `yaml:"service_group"`
    ServiceUser    string `yaml:"service_user"`
    
}

func main() {
    configFile  := flag.String("i", "", "publish.yml path")
    cmdType     := flag.String("s", "", "before/after/deploy/related_plan")
    
    flag.Parse()

    if *configFile == "" || *cmdType == "" {
        fmt.Println("invalid arguments")
        return
    }

    fileContent, err := ioutil.ReadFile(*configFile)
    if err!=nil {
        panic(err)
    }

    var config ProjectPubConfig
    yaml.Unmarshal(fileContent, &config)

    switch(*cmdType) {
        case "project_name":
            fmt.Printf(config.ProjectName)
        case "before":
            fmt.Printf(config.BeforeCmd)
        case "after":
            fmt.Printf(config.AfterCmd)
        case "deploy":
            fmt.Printf(config.DeployTo)
        case "service_group":
            fmt.Printf(config.ServiceGroup)
        case "service_user":
            fmt.Printf(config.ServiceUser)
        case "related_plan":
            fmt.Printf(config.RelatedProject)
        default:
        os.Exit(1)
    }
}

