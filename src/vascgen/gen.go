package main

import "flag"
import "fmt"
import "go/ast"
import "go/parser"
import "go/token"
import "io/ioutil"
import "reflect"
import "strings"
import "encoding/json"
import "github.com/marxn/vasc"


func loadVascConfigFile(fileName string) (*vasc.VascConfig, error) {
    config, err := ioutil.ReadFile(fileName)
    if err != nil{
        return nil, err
    }
    
    jsonResult := new(vasc.VascConfig)
    err = json.Unmarshal([]byte(config), jsonResult)
    if err != nil {
        return nil, err
    }
    
    return jsonResult, err
}

func main() {
	input              := flag.String("i", "", "input source file name")
	vascConfigFileName := flag.String("c", "", "vasc config file")
	output             := flag.String("o", "", "output source file")

	flag.Parse()

	if *input == "" || *output == "" {
		fmt.Println("invalid arguments")
		return
	}
	
	vascConfig, err := loadVascConfigFile(*vascConfigFileName)
	if err!=nil {
	    fmt.Println(err)
	    return
	}
	
	fset := token.NewFileSet()
	f, err := parser.ParseFile(fset, *input, nil, 0)
	if err != nil {
		panic(err)
	}

	source := fmt.Sprintf("package %s\n\n//Vasc generated code. Do not modify.\nimport \"github.com/marxn/vasc\"\n\nvar VascFuncMap = map[string]func(){\n", f.Name)

	for _, value := range f.Decls {
		t := reflect.TypeOf(value)
		s := t.String()
		if strings.Contains(s, "FuncDecl") {
			funcName := value.(*ast.FuncDecl).Name
			source = fmt.Sprintf("%s    \"%s\": %s,\n", source, funcName, funcName)
		}
	}
	
	source += fmt.Sprintf("}\n\nfunc main() {")
	source += fmt.Sprintf("err := vasc.InitInstance(                \n")
	source += fmt.Sprintf("    &vasc.VascApplication{               \n")
	source += fmt.Sprintf("        WebserverRoute: []vasc.VascRoute{\n")
	
	for _, value := range vascConfig.Application.WebserverRoute {
	source += fmt.Sprintf("            vasc.VascRoute{Method:\"%s\", Route:\"%s\", Middleware: %s, RouteHandler: %s, LocalFilePath: \"%s\"},\n", 
	    value.Method, value.Route, value.MiddlewareName, value.HandlerName, value.LocalFilePath)
	}
	
	source += fmt.Sprintf("        },\n")
    source += fmt.Sprintf("        TaskList: []vasc.TaskInfo {\n")
    
    for _, value := range vascConfig.Application.TaskList {
    source += fmt.Sprintf("            vasc.TaskInfo{Key: \"%s\", Handler: %s, HandlerNum: %d, Scope: %d, QueueSize: %d},\n", 
        value.Key, value.HandlerName, value.HandlerNum, value.Scope, value.QueueSize)
    }
    
    source += fmt.Sprintf("        },\n")
    source += fmt.Sprintf("        ScheduleList: []vasc.ScheduleInfo{\n")
    
    for _, value := range vascConfig.Application.ScheduleList {
    source += fmt.Sprintf("            vasc.ScheduleInfo {Key: \"%s\", Routine: %s, Type: %d, Interval: %d, Timestamp: %d, Scope: %d},\n",
        value.Key, value.HandlerName, value.Type, value.Interval, value.Timestamp, value.Scope)
    }
	
	source += fmt.Sprintf("        },\n")
	source += fmt.Sprintf("        FuncMap: VascFuncMap,\n")
	source += fmt.Sprintf("    })\n\n")
	
	source += fmt.Sprintf("    if err!=nil {     \n")
	source += fmt.Sprintf("        panic(err)    \n")
	source += fmt.Sprintf("        return        \n")
	source += fmt.Sprintf("    }                 \n")
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
