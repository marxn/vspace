#!/bin/bash
publish_project() {
    hostname=$1
    username=$2
    projectname=$3
    tag=$4
    packagepath=$GOPATH/target/$projectname/$tag/$projectname
    scp -q $packagepath $username@$hostname:~/$projectname
}

if [ "$#" -gt "2" ]; then
    echo "useage: vmt.sh <-b -p -g> <baseline>"
    exit 1
fi

action=build
while [ $# -ge 1 ] ; do
    case "$1" in
        -b) baseline=$2; action=build; shift 2;;
        -p) baseline=$2; action=publish; shift 2;;
        -g) baseline=$2; action=generate; shift 1;;
         *) echo "unknown parameter $1." ; exit 1 ; break;;
    esac
done

export PATH=$PATH:`pwd`/bin
export GOPATH=`pwd`

cwd=`pwd`

if [ "$action" == "build" ]; then
    cd $GOPATH/vpcm/
    git pull
    baselines=`cat $GOPATH/vpcm/baseline/$baseline`
    for item in $baselines
    do
        tag=${item##*/}
        projectname=${item%%/*}
        packagepath=$GOPATH/target/$projectname/$tag
        if [ ! -d "$packagepath" ]; then
            ./build.sh -p $projectname -t $tag
        fi
    done
    cd $cwd
    exit 0
fi

if [ "$action" == "generate" ]; then
    uuid=`cat /proc/sys/kernel/random/uuid`
    timestamp=`date -d "now" '+%Y%m%d-%H%M%S'`
    newbaseline="$timestamp--$uuid"
    #touch $GOPATH/vpcm/baseline/$newbaseline

    while read line
    do
        projectname=${line%% *}
        echo "Adding $projectname"
        if [ ! -f "$GOPATH/src/$projectname/version.txt" ]; then
            echo -e "\033[31mCannot find source code version.txt for project:$projectname\033[0m"
            exit 1
        fi
        tag=`cat $GOPATH/src/$projectname/version.txt`
        if [ "$tag" == "" ]; then
            echo -e "\033[31mEmpty version.txt for project:$projectname\033[0m"
            exit 1
        fi
        echo "$projectname/$tag" >> $GOPATH/vpcm/baseline/$newbaseline
    done < $GOPATH/vpcm/global/project_list.scm
    echo -e "\033[32mGenerating new baseline successfully.\nNew baseline: $newbaseline\033[0m"
    echo -e "Do you want to commit this baseline?(yes/no):\c"
    read commit
    if [ "$commit" == "yes" ]; then
        cd $GOPATH/vpcm/baseline/
        git add $newbaseline
        git commit -m "$newbaseline"
        git push
    fi
    cd $cwd
    echo -e "Do you want to publish project(s) in this baseline?(yes/no):\c"
    read publish
    if [ "$publish" == "yes" ]; then
        action=publish
        baseline=$newbaseline
    else
        exit 0
    fi
fi

if [ "$action" == "publish" ]; then
    username=`id -un`
    projectroot="/home/$username/project"
    while read hostname
    do
        scp -q  $username@$hostname:$projectroot/baseline ./baseline.$hostname
        if [ ! -f /tmp/baseline.$hostname ]; then
            echo -e "\033[31mCannot fetch remote baseline for host:$hostname\033[0m"
            exit 1
        fi
        
        while read line
        do
            tag=${line##*/}
            projectname=${line%%/*}

            echo "Comparing $hostname version..."
            remoteitem=`grep -E "^$projectname/" ./baseline.$hostname`
            remotetag=${remoteitem##*/}
            if [ "$tag" != "$remotetag" ]; then
                echo -e "\033[33m$projectname: $remotetag -> $tag\033[0m"
                publish_project $hostname $username $projectname $tag
            fi
        done < $GOPATH/vpcm/baseline/$baseline
        rm -f ./baseline.$hostname
    done < $GOPATH/vpcm/global/host_list.scm    
fi

