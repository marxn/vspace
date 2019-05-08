#!/bin/bash
if [ "$#" -lt "4" ]; then
    echo "useage: build.sh -p <project_name> -t <tag> -a <yes/no>"
    exit 1
fi

puff="no"
while [ $# -ge 2 ] ; do
    case "$1" in
        -p) projectname=$2; shift 2;;
        -t) tag=$2; shift 2;;
        -a) puff=$2; shift 2;;
         *) echo "unknown parameter $1." ; exit 1 ; break;;
    esac
done

export PATH=$PATH:`pwd`/bin
export GOPATH=`pwd`

if [ ! -d "$GOPATH/src/$projectname/" ];then
    project_addr=`cat $GOPATH/vpcm/project/$projectname/project_addr.scm`
    if [ -z "$project_addr" ]; then
        exit 1
    fi
    git clone $project_addr $GOPATH/src/$projectname
fi

cdir=`pwd`
cd $GOPATH/src/$projectname
git pull
git checkout $tag

if [ "$puff"=="yes" ];then
    echo Start to generate code...
    cd $GOPATH/src
    rm -f $projectname/puff_main.go
    puff -i $projectname -o $projectname/puff_main.go -c $GOPATH/vpcm/project/$projectname/conf/vasc_conf.json
fi

cd $GOPATH/src/$projectname
go build -o $projectname
if [ "$?" -ne "0" ]; then
    echo "Cannot build target. break"
    exit 1
fi

mkdir -p $GOPATH/target/$projectname/$tag
cp $projectname $GOPATH/target/$projectname/$tag/$projectname
git checkout master

cd $cdir
