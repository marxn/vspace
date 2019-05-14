# vspace
vspace是一个工作平台，它包括软件配置管理、版本控制、服务发布等功能。目前已经与vasc框架无缝结合，可以用于实现基于go语言开发的项目的管理。
## 如何部署vspace
### 1.安装GO语言开发环境
请参考http://docs.studygolang.com/doc/install
### 2.从github获取vspace：
```
git clone https://github.com/marxn/vspace.git
```
### 2. 设置环境变量
编辑用户根目录下的.bash_profile，加入以下内容：
```
GOROOT=/usr/local/go/
GOPATH=$HOME/vspace/
PATH=$PATH:/usr/local/go/bin:$HOME/vspace/tools
```
注意：vspace使用自己的GOPATH目录，因此如果用户以前设置了GOPATH是无法使用的。
### 3. 初始化vspace依赖的资源
vspace包含版本控制和配置管理的功能。因此需要导入一个本地git代码库VPCM来实现版本和配置管理。重新登陆以后，在vspace目录下执行以下命令
```
./init.sh <VPCM项目的git地址>
例如：
./setup git@gitlab.mararun.cn:pcm/vpcm-test.git
```
init.sh会自动从第三方网站拉取依赖的go代码库和其他依赖。
