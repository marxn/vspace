package main

import "flag"
import "fmt"
import "bytes"
import "os/exec"
import "go/ast"
import "go/parser"
import "go/token"
import "io/ioutil"
import "reflect"
import "strings"
import "encoding/json"
import "github.com/marxn/vasc/global"

type funcItem struct {
    Comment  string
    FuncName string
}

type directoryInfo struct {
    Dir           string
    FileList    []string
    FuncList    []funcItem
    CommentList []string
    NeedExport    bool
}

func ExecShellCmd(s string) (string, error) {
	cmd := exec.Command("/bin/bash", "-c", s)
	var out bytes.Buffer
	cmd.Stdout = &out
	err := cmd.Run()
	return out.String(), err
}

func emptyDir(path string) bool {
    cmd := fmt.Sprintf("find %s -name '*.go'", path)
    ret, err := ExecShellCmd(cmd)
    if err!=nil {
        return true
    }
    if ret == "" {
        return true
    }
    return false
}

func getDirList(path string) ([]string, error) {
    cmd := fmt.Sprintf("find %s -type d", path)
    ret, err := ExecShellCmd(cmd)
    if err!=nil {
        return nil, err
    } 
    
    var result []string
    for _, value := range strings.Split(ret, "\n") {
        if value!="" && value != "." && value != ".." && !emptyDir(value) {
            result = append(result, value)
        }
    }
    return result, nil
}

func getFileList(path string) ([]string, error) {
    cmd := fmt.Sprintf("find %s -maxdepth 1 -name '*.go'", path)
    ret, err := ExecShellCmd(cmd)
    if err!=nil {
        return nil, err
    } 
    
    var result []string
    for _, value := range strings.Split(ret, "\n") {
        if value!="" {
            result = append(result, value)
        }
    }
    
    return result, nil
}

func loadVascConfigFile(fileName string) (*global.VascConfig, error) {
    config, err := ioutil.ReadFile(fileName)
    if err != nil{
        return nil, err
    }
    
    jsonResult := new(global.VascConfig)
    err = json.Unmarshal([]byte(config), jsonResult)
    if err != nil {
        return nil, err
    }
    
    return jsonResult, err
}

func isExported(funcName string) bool {
    nameBytes := []byte(funcName)
    if len(nameBytes) > 0 {
        return nameBytes[0] >= 65 && nameBytes[0] <= 90
    }
    return false
}

func getExportFuncList(fileList []string) ([]funcItem, error) {
    var result []funcItem
    for _, filename := range fileList {
        fset := token.NewFileSet()
    	f, err := parser.ParseFile(fset, filename, nil, parser.ParseComments)
    	if err != nil {
    		panic(err)
    	}
    	for _, value := range f.Decls {
    		t := reflect.TypeOf(value)
    		s := t.String()
    		if strings.Contains(s, "FuncDecl") {
    		    decl := value.(*ast.FuncDecl)
    			funcName := decl.Name
    			if !isExported(fmt.Sprintf("%s", funcName)) {
    			    continue
    			}
    			funcDesc := &funcItem{Comment: "", FuncName: fmt.Sprintf("%s", funcName)}
    			doc  := decl.Doc
            	if doc!=nil {
            	    for _, docItem := range doc.List {
                	    headByte := []byte(docItem.Text)
                	    if string(headByte[0:3])=="///" && len(headByte[3:]) > 8 {
                	        funcDesc.Comment = string(headByte[3:])
                	    }
                	}
            	}
            	if funcDesc.Comment!="" {
    			    result = append(result, *funcDesc)
    			}
            }
        }
    }
    return result, nil
}

func qualifyPath(path string) string {
    index := strings.Index(path, "/")
    if index >= 0 {
        ret := []byte(path)
        return string(ret[index + 1:])
    }
    return ""
}

func main() {
    var handlerHolder  []string
    var scheduleHolder []string
    var taskHolder     []string

	input              := flag.String("i", "", "input source file directory")
	vascConfigFileName := flag.String("c", "", "vasc config file")
	output             := flag.String("o", "", "output source file")
    
	flag.Parse()

	if *input == "" || *output == "" {
		fmt.Println("invalid arguments")
		return
	}

    sourceInfo := make(map[string]*directoryInfo)
    
    dirList, err := getDirList(*input)
    if err!=nil {
        panic(err)
    }
	
	for _, value := range dirList {
	    fmt.Println("analyzing directory:" + value)
	    dirInfo := new(directoryInfo)
	    dirInfo.Dir = value
    	fileList, err := getFileList(value)
    	if err!=nil {
    	    panic(err)
    	}
    	
	    dirInfo.FileList = fileList
	    funcList, err := getExportFuncList(fileList)
	    if err!=nil {
	        panic(err)
	    }
	    if len(funcList) > 0 {
	        dirInfo.FuncList   = funcList
	        dirInfo.NeedExport = true
	    }
	    sourceInfo[value] = dirInfo
	}
	
	source := fmt.Sprintf("//Vasc generated code. Do not modify.\n\npackage main\n\nimport \"github.com/marxn/vasc\"\nimport \"github.com/marxn/vasc/global\"\n")
	
	for _, value := range sourceInfo {
	    if value.NeedExport {
	        source += fmt.Sprintf("import \"%s\"\n", value.Dir)
	    }
	}
	
	source += "\n\nvar VascFuncMap = map[string]interface{}{\n"

    for _, sourceCode := range sourceInfo {
        for _, funcCall := range sourceCode.FuncList {
            source += fmt.Sprintf("    \"%s\": %s.%s,\n", funcCall.FuncName, qualifyPath(sourceCode.Dir), funcCall.FuncName)
            if funcCall.Comment!="" {
                defination := []byte(funcCall.Comment)
                if string(defination[0:7])=="HANDLER" {
                    handlerHolder = append(handlerHolder, string(defination[7:]) + fmt.Sprintf(", \"route_handler\": \"%s\"", funcCall.FuncName))
                } else if string(defination[0:8])=="SCHEDULE" {
                    scheduleHolder = append(scheduleHolder, string(defination[8:]) + fmt.Sprintf(", \"handler\": \"%s\"", funcCall.FuncName))
                } else if string(defination[0:4])=="TASK" {
                    taskHolder = append(taskHolder, string(defination[4:]) + fmt.Sprintf(", \"handler\": \"%s\"", funcCall.FuncName))
                }
            }
        }
    }
	source += fmt.Sprintf("}\n")
	
	configFile, err := ioutil.ReadFile(*vascConfigFileName)
    if err!=nil {
	    panic(err)
	}
	source += fmt.Sprintf("\n\nvar configFile = `%s`", configFile)
	
	appConfigFile := fmt.Sprintf("\n{\n")
	appConfigFile += fmt.Sprintf("        \"schedule_list\": [\n")
	for index, schedule := range scheduleHolder {
    appConfigFile += fmt.Sprintf("            {%s}", schedule)
    if index < len(scheduleHolder) - 1 {
        appConfigFile += fmt.Sprintf(",")
    }
    appConfigFile += fmt.Sprintf("\n")
	}
	appConfigFile += fmt.Sprintf("        ],\n")
	
	appConfigFile += fmt.Sprintf("        \"task_list\": [\n")
	for index, task := range taskHolder {
	appConfigFile += fmt.Sprintf("            {%s}", task)
	if index < len(taskHolder) - 1 {
        appConfigFile += fmt.Sprintf(",")
    }
    appConfigFile += fmt.Sprintf("\n")
	}
	appConfigFile += fmt.Sprintf("        ],\n")

    appConfigFile += fmt.Sprintf("        \"webserver_route\": [\n")
	for index, handler := range handlerHolder {
	appConfigFile += fmt.Sprintf("            {%s}", handler)
    if index < len(handlerHolder) - 1 {
        appConfigFile += fmt.Sprintf(",")
    }
    appConfigFile += fmt.Sprintf("\n")
	}
	appConfigFile += fmt.Sprintf("        ]\n")
	appConfigFile += fmt.Sprintf("}\n")
	
	source += fmt.Sprintf("\n\nvar appConfigFile = `%s`\n", appConfigFile)

	source += fmt.Sprintf("func main() {\n")
	source += fmt.Sprintf("err := vasc.InitInstance(\n")
	source += fmt.Sprintf("    &global.VascApplication{\n")
	source += fmt.Sprintf("        FuncMap: VascFuncMap,\n")
	source += fmt.Sprintf("        Configuration: configFile,\n")
	source += fmt.Sprintf("        AppConfiguration: appConfigFile,\n")
	source += fmt.Sprintf("    })\n\n")
	
	source += fmt.Sprintf("    if err!=nil {\n")
	source += fmt.Sprintf("        panic(err)\n")
	source += fmt.Sprintf("        return\n")
	source += fmt.Sprintf("    }\n")
	source += fmt.Sprintf("    defer vasc.Close()\n")
	source += fmt.Sprintf("\n")
	source += fmt.Sprintf("    vasc.StartService()\n")
	source += fmt.Sprintf("    vasc.Wait()\n")
	source += fmt.Sprintf("}\n")

	err = ioutil.WriteFile(*output, []byte(source), 0666)
	if err != nil {
		fmt.Println("Cannot write output file:" + err.Error())
	}
	
	fmt.Println("Code generated.")
}
