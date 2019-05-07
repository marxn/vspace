#!/bin/bash

if [ "$#" -ne "1" ]; then
    echo "useage build.sh <vpcm_address>"
    exit 1
fi

export PATH=$PATH:`pwd`/bin
export GOPATH=`pwd`

if [ ! -d "$GOPATH/src/golang.org/" ];then
    echo "Building up some dependencies out of door..."
    mkdir -p $GOPATH/src/golang.org/x
    git clone https://github.com/golang/net.git $GOPATH/src/golang.org/x/net
    git clone https://github.com/golang/sys.git $GOPATH/src/golang.org/x/sys
    git clone https://github.com/golang/tools.git $GOPATH/src/golang.org/x/tools
fi

dependencies=`cat dependencies`
for item in $dependencies
do
    echo "Fetching dependencies:" $item
    go get $item
    echo "Done"
done

echo "Denpendencies fetched."

if [ ! -d "$GOPATH/vpcm" ];then
    echo "Importing SCM module..."
    git clone $1 $GOPATH/vpcm
    echo "Done."
fi

