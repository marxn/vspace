package main

import "flag"
import "fmt"
import "os"
import "io/ioutil"
import "encoding/json"

type Plan struct {
        ProjectName    string `json:"project_name"`
        DeployTo       string `json:"deploy_to"`
        BeforeCmd      string `json:"before_cmd"`
        AfterCmd       string `json:"after_cmd"`
        RelatedProject string `json:"related_plan"`
        ServiceGroup   string `json:"service_group"`
        ServiceUser    string `json:"service_user"`
}

type ProjectPubConfig struct {
    GoArch         string          `json:"goarch"`
    GoOs           string          `json:"goos"`
    ServiceRoot    string          `json:"service_root"`
    HostList     []string          `json:"host_list"`
    Plans          map[string]Plan `json:"plans"`
}

func main() {
    configFile  := flag.String("i", "", "config file path")
    projectName := flag.String("p", "", "project name")
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
    json.Unmarshal(fileContent, &config)

    switch(*cmdType) {
        case "goarch":
            fmt.Printf(config.GoArch)
        case "goos":
            fmt.Printf(config.GoOs)
        case "service_root":
            fmt.Printf(config.ServiceRoot)
        case "hostlist":
            for _, value := range config.HostList {
                fmt.Println(value)
            }
        case "before":
            fmt.Printf(config.Plans[*projectName].BeforeCmd)
        case "after":
            fmt.Printf(config.Plans[*projectName].AfterCmd)
        case "deploy":
            fmt.Printf(config.Plans[*projectName].DeployTo)
        case "service_group":
            fmt.Printf(config.Plans[*projectName].ServiceGroup)
        case "service_user":
            fmt.Printf(config.Plans[*projectName].ServiceUser)
        case "related_plan":
            fmt.Printf(config.Plans[*projectName].RelatedProject)
        default:
            os.Exit(1)
    }
}

