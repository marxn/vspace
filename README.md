# vspace
vspace是一个工作平台，它包括软件配置管理、版本控制、服务发布等功能。目前已经与vasc框架无缝结合，可以用于实现基于go语言开发的项目的管理。
## 如何部署vspace
### 1.安装GO语言开发环境
请参考http://docs.studygolang.com/doc/install
### 2.从github获取vspace：
```
git clone https://github.com/marxn/vspace.git
```
### 3. 设置环境变量
编辑用户根目录下的.bash_profile，加入以下内容：
```
GOROOT=/usr/local/go/
GOPATH=$HOME/vspace/
PATH=$PATH:/usr/local/go/bin:$HOME/vspace/tools
```
注意：vspace使用自己的GOPATH目录，因此如果用户以前设置了GOPATH是无法使用的。
### 4. 初始化vspace依赖的资源
vspace包含版本控制和配置管理的功能。因此需要导入一个本地git代码库VPCM来实现版本和配置管理。重新登陆以后，在vspace目录下执行以下命令
```
./init.sh <VPCM项目的git地址>
例如：
./init.sh git@gitlab.mararun.cn:pcm/vpcm-test.git
```
init.sh会自动从第三方网站拉取依赖的go代码库和其他依赖。
## 如何用vspace进行版本控制
开发者编辑vspace/vpcm/global/project_list.scm文件，将工程名和git上对应的地址追加到文件末尾，vspace会自动将此项目纳入管理。  
vspace提供一个用于版本提交的小工具/vspace/tools/st。开发者完成代码编辑和提交之后，可以用这个小工具生成项目的版本号并写入项目目录下的version.txt。同时在git上打tag。  
```
useage: st -u <版本号增量> -m <注释>
例如: 
原始version.txt的内容为0.0.0.1
st -u 0.0.1.1 -m "测试"
之后version.txt变为0.0.1.2
```
## 如何用vspace进行服务发布
### 1.在目标服务器建立服务运行环境
vspace通过以下配置文件在目标服务器上部署服务，开发者需要编辑这些文件来实现服务部署：
```
vspace/vpcm/global/service_root.env 需要部署的服务根目录
vspace/vpcm/global/service_user.env 需要部署的服务对应的linux用户名
vspace/vpcm/global/service_group.env 需要部署的服务对应的linux用户组名
```
系统管理员在目标服务器上为服务发布管理员开通账号，并授予sudo权限。
### 2.使用vmt.sh进行基线管理和服务发布
/vspace/vmt.sh是一个用于服务发布的工具。用法如下：
```
useage: vmt.sh <-g -p -f> [<baseline>]
Example: vmt.sh -g [baseline]   为所有项目生成一个新的基线。基线在/vspace/vpcm/baseline中进行管理。
Example: vmt.sh -p <baseline>   将基线包含的项目按照指定的版本发布到对应服务器上。此选项只发布与目标服务器上版本不同的项目。
Example: vmt.sh -f <baseline>   强制将基线包含的项目按照指定的版本发布到对应服务器上。
```
