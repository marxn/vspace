#!/bin/bash
if [ "$#" -ne "4" ]; then
    echo "useage: update.sh -p <project_name> -t <tag>"
    exit 1
fi

while [ $# -ge 2 ] ; do
    case "$1" in
        -p) projectname=$2; shift 2;;
        -t) tag=$2; shift 2;;
         *) echo "unknown parameter $1." ; exit 1 ; break;;
    esac
done

export PATH=$PATH:`pwd`/bin
export GOPATH=`pwd`

echo "Making some tools..."
make -s -C $GOPATH/src/vascgen
cp $GOPATH/src/vascgen/vascgen $GOPATH//bin

if [ ! -d "$GOPATH/src/$projectname/" ];then
    project_addr=`cat $GOPATH/vpcm/project/$projectname/project_addr.scm`
    if [ -z "$project_addr" ]; then
        exit 1
    fi
    git clone $project_addr $GOPATH/src/$projectname
fi

cdir=`pwd`
cd $GOPATH/src/$projectname
#git pull
#git checkout $tag

if [ ! -f "$GOPATH/src/$projectname/Main.go" ]; then
    echo Start to generate code...
    cd $GOPATH/src
    vascgen -i $projectname -o $projectname/Main.go -c $GOPATH/vpcm/project/$projectname/conf/vasc_conf.json
fi

cd $GOPATH/src/$projectname
go build -o $projectname
mkdir -p $GOPATH/target/$tag/$projectname
cp $projectname $GOPATH/target/$tag/$projectname/$projectname
#git checkout master

cd $cdir
