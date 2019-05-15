#!/bin/bash
vpcm_addr=$1
baseline_addr=$2

if [ ! -d "$GOPATH/src/golang.org/" ];then
    echo "Building up some dependencies out of door..."
    mkdir -p $GOPATH/src/golang.org/x
    git clone https://github.com/golang/net.git $GOPATH/src/golang.org/x/net
    git clone https://github.com/golang/sys.git $GOPATH/src/golang.org/x/sys
    git clone https://github.com/golang/tools.git $GOPATH/src/golang.org/x/tools
fi

dependencies=`cat $GOPATH/dependencies`
for item in $dependencies
do
    echo "Fetching dependencies:" $item
    go get $item
    echo "Done"
done

echo "Denpendencies fetched."

if [ ! -d "$GOPATH/vpcm" ];then
    if [ "$vpcm_addr" != "" ];then
        echo "Importing SCM module..."
        git clone $vpcm_addr $GOPATH/vpcm
        echo "Done."
    else
        echo "Notice: $GOPATH/vpcm directory does not exist."
    fi
fi

if [ ! -d "$GOPATH/vpcm/baseline" ];then
    if [ "$baseline_addr" != "" ];then
        echo "Importing baseline..."
        git clone $baseline_addr $GOPATH/vpcm/baseline
    else
        echo "Notice: $GOPATH/vpcm/baseline directory does not exist."
    fi
fi
