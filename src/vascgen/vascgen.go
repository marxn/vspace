package main

import "flag"
import "fmt"
import "os"
import "go/ast"
import "go/parser"
import "go/token"
import "io/ioutil"
import "reflect"
import "strings"
import "encoding/json"
import "path/filepath"
import "github.com/marxn/vasc/global"

func getFilelist(path string) ([]string, error) {
    fileList := make([]string, 0)
    err := filepath.Walk(path, func(path string, f os.FileInfo, err error) error {
        if ( f == nil ) {return err}
        if f.IsDir() {return nil}
        fileList = append(fileList, path)
        return nil
    })
    if err != nil {
        fmt.Printf("filepath.Walk() returned %v\n", err)
    }
    return fileList, nil
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

func main() {
    var handlerHolder  []string
    var scheduleHolder []string
    var taskHolder     []string

	input              := flag.String("i", "", "input source file directory")
	vascConfigFileName := flag.String("c", "", "vasc config file")
	output             := flag.String("o", "", "output source file")
    projectName        := flag.String("p", "", "project name")
    
	flag.Parse()

	if *input == "" || *output == "" {
		fmt.Println("invalid arguments")
		return
	}
	/*
	vascConfig, err := loadVascConfigFile(*vascConfigFileName)
	if err!=nil {
	    fmt.Println(err)
	    return
	}
	*/
	fileList, err := getFilelist(*input)
	if err!=nil {
	    panic(err)
	}
	
	source := fmt.Sprintf("package main\n\n//Vasc generated code. Do not modify.\nimport \"github.com/marxn/vasc\"\nimport \"github.com/marxn/vasc/global\"\n")
	source += fmt.Sprintf("import \"%s/%s\"", *projectName, *input)
	
	configFile, err := ioutil.ReadFile(*vascConfigFileName)
    if err!=nil {
	    panic(err)
	}
	
	source += fmt.Sprintf("\n\nvar configFile = `%s`", configFile)
	source += "\n\nvar VascFuncMap = map[string]interface{}{\n"

	for _, filename := range fileList {
	    fmt.Println(filename)
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
    			if isExported(fmt.Sprintf("%s", funcName)) {
    	   		    doc  := decl.Doc
        		    if doc!=nil {
                	    for _, docItem := range doc.List {
                	        headByte := []byte(docItem.Text)
                	        if string(headByte[0:3])=="///" && len(headByte[3:]) > 8 {
                	            defination := headByte[3:]
                	            if string(defination[0:7])=="HANDLER" {
                	                handlerHolder = append(handlerHolder, string(defination[7:]) + fmt.Sprintf(", \"route_handler\": \"%s\"", funcName))
    			                    source = fmt.Sprintf("%s    \"%s\": %s.%s,\n", source, funcName, f.Name, funcName)
                	            } else if string(defination[0:8])=="SCHEDULE" {
                	                scheduleHolder = append(scheduleHolder, string(defination[8:]) + fmt.Sprintf(", \"handler\": \"%s\"", funcName))
    			                    source = fmt.Sprintf("%s    \"%s\": %s.%s,\n", source, funcName, f.Name, funcName)
                	            } else if string(defination[0:4])=="TASK" {
                	                taskHolder = append(taskHolder, string(defination[4:]) + fmt.Sprintf(", \"handler\": \"%s\"", funcName))
    			                    source = fmt.Sprintf("%s    \"%s\": %s.%s,\n", source, funcName, f.Name, funcName)
                	            }
                	        }
                	    }
                	}
    			}
    		}
    	}
	}
	
	source += fmt.Sprintf("}\n")
	
	appConfigFile := fmt.Sprintf("\n{\n")
	//appConfigFile += fmt.Sprintf("    \"application\": {\n")
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
	//appConfigFile += fmt.Sprintf("    }\n")
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
}
