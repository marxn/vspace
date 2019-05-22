#!/bin/bash
tag=""
result="0"
if [ "$#" -lt "2" ]; then
    echo "useage: build.sh -p <project_name> [-t <tag>]"
    exit 1
fi

while [ $# -ge 2 ] ; do
    case "$1" in
        -p) projectname=$2; shift 2;;
        -t) tag=$2; shift 2;;
         *) echo "unknown parameter $1." ; exit 1 ; break;;
    esac
done

if [ ! -d "$GOPATH/src/$projectname/" ];then
    project_addr=`cat $GOPATH/vpcm/project/$projectname/project_addr.scm`
    if [ -z "$project_addr" ]; then
        exit 1
    fi
    git clone $project_addr $GOPATH/src/$projectname
fi

cdir=`pwd`
cd $GOPATH/src/$projectname

current_branch=`git rev-parse --abbrev-ref HEAD`
if [ "$tag" != "" ]; then
    git checkout -q $tag
    if [ "$?" -ne "0" ]; then
        echo "Cannot checkout tag:$tag. break"
        exit 1
    fi
fi

if [ -f $GOPATH/src/$projectname/enable_puff ];then
    echo "Start to generate puff_main.go..."
    cd $GOPATH/src
    rm -f $projectname/puff_main.go
    puff -i $projectname -o $projectname/puff_main.go -c $GOPATH/vpcm/project/$projectname/conf/vasc_conf.json
fi

cd $GOPATH/src/$projectname
mkdir -p $GOPATH/target/$projectname/$tag
make DESTNATION="$GOPATH/target/$projectname/$tag"
if [ "$?" -ne "0" ]; then
    echo "Cannot build target. break"
    rm -rf $GOPATH/target/$projectname/$tag
    result="1"
fi

git checkout -q $current_branch

exit result