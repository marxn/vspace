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

type ProjectInfo struct {
    ProjectName           string `json:"project_name"`
    Address               string `json:"address"`
    NeedIncludedBaseline  string `json:"need_included_baseline"`
    NeedPublish           string `json:"need_publish"`
    PlanList              string `json:"plan_list"`
    DefaultBranch         string `json:"default_branch"`
}

type ProjectPubConfig struct {
    GoArch         string          `json:"goarch"`
    GoOs           string          `json:"goos"`
    GoDep          string          `json:"godep"`
    ServiceRoot    string          `json:"service_root"`
    NginxAddr      string          `json:"nginx_conf_path"`
    HostList     []string          `json:"host_list"`
    ProjectList  []ProjectInfo     `json:"project_list"`
    Plans          map[string]Plan `json:"plans"`
}

func main() {
    configFile  := flag.String("i", "", "config file path")
    projectName := flag.String("p", "", "project name")
    cmdType     := flag.String("s", "", "action name")
    
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
        case "nginx_addr":
            fmt.Printf(config.NginxAddr)
        case "godep":
            fmt.Printf(config.GoDep)
        case "hostlist":
            for _, value := range config.HostList {
                fmt.Println(value)
            }
        case "projectlist":
            for _, value := range config.ProjectList {
                fmt.Printf("%s %s %s %s %s %s\n", value.ProjectName, value.Address, value.NeedIncludedBaseline, value.NeedPublish, value.PlanList, value.DefaultBranch)
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

