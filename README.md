# vspace
vspace是一个工作平台，它包括软件配置管理、版本控制、服务发布等功能。与vasc框架结合，可以用于实现基于go语言开发的项目版本控制和服务发布。
## 如何部署vspace
### 1.安装GO语言开发环境
请参考http://docs.studygolang.com/doc/install
如果之前已经安装过GO语言开发环境，可以跳过此步。
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
### 4. 初始化vspace和vasc依赖的资源
vspace包含版本控制和配置管理的功能。因此需要导入一个本地git代码库VPCM来实现版本和配置管理。重新登陆以后，在vspace目录下执行以下命令
```
./init [VPCM项目的git地址] [baseline的git地址]
例如：
./init git@gitlab.mararun.cn:scm/vpcm.git git@git.mararun.cn:scm/mara-baseline.git
```
init会自动从第三方网站拉取生成服务所依赖的go代码库。发版管理员可编辑vspace/dependencies来拉取开发者代码所依赖的库。  
## 如何用vspace进行版本控制
开发者可以编辑vspace/vpcm/project_list.scm文件，将工程名和git上对应的地址追加到文件末尾，vspace会自动将此项目纳入基线管理。  
vspace提供一个用于版本提交的小工具/vspace/tools/vst。开发者完成代码编辑和提交之后，可以用这个小工具生成项目的版本号并写入项目目录下的version.txt。同时在git上打tag。  
```
usage: vst -u <s/f/b/w>
s/f/b/w分别控制版本号的四个部分。提交大的版本号以后后面的小版本号自动清零。
例如: 
原始version.txt的内容为0.0.0.1
st -u b
之后version.txt变为0.0.1.0
```
## 如何用vspace进行服务发布
### 1.在目标服务器建立服务运行环境
系统管理员在目标服务器上建立用于部署服务的用户账号和服务部署的目录，并且为发版管理员开通账号，并授予sudo权限。  
配置管理员使用自己的帐号登录目标服务器，并设置免密码登录：
#### 1.在需要发版的源主机A生产密钥对: ssh-keygen -t rsa， 会在.ssh目录下产生密钥文件
#### 2.拷贝源主机A的公钥到主机B的home目录下: scp id_rsa.pub xxx@xxx.com:/home/xxx
#### 3.将主机A的公钥加到主机B的授权列表.ssh/authorized_keys（若不存在，手动创建）: cat id_rsa.pub >> authorized_keys 
#### 4.授权列表authorized_keys的权限必须是400，chmod 600 authorized_keys
#### 5..ssh目录的权限为600，chmod 600 .ssh
使用ssh连接目标服务器，如果没有弹出输入密码表明设置成功。

### 2.使用vmt进行基线管理和服务发布
vmt是一个用于服务发布的工具。用法如下：
```
usage: vmt <-g -c -p -f> [<baseline>]
Example: vmt -g    按照当前src路径下的所有项目的当前分支生成一个新的基线。基线在/vspace/vpcm/baseline中进行管理。
Example: vmt -c    按照当前src路径下打所有项目的master分支生成一个新的基线。基线在/vspace/vpcm/baseline中进行管理。
Example: vmt -p <baseline>   将基线包含的项目按照指定的版本发布到对应服务器上。此选项只发布与目标服务器上版本不同的项目。
Example: vmt -f <baseline>   强制将基线包含的项目按照指定的版本发布到对应服务器上。
```
vmt会遍历项目列表，如果列表定义的某个项目不在本地，那么会自动拉取项目代码并进行编译打包，放置在vspace/target/目录中。  
vmt会自动检测某个本地项目是否已正确打版本号。如果开发者提交了更改但未修改version.txt打版本，那么在生成基线时vmt.sh会给出提示并中断。  
