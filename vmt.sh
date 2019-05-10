#!/bin/bash
username=`id -un`
projectroot="$HOME/project"

publish_project() {
    hostname=$1
    username=$2
    projectname=$3
    tag=$4
    nginx_conf_path=""
    
    cp $GOPATH/tools/vasc_init.sh $GOPATH/target/$projectname/$tag
    cp $GOPATH/tools/vasc_stop.sh $GOPATH/target/$projectname/$tag
    cp $GOPATH/tools/vasc_start.sh $GOPATH/target/$projectname/$tag
    cp $GOPATH/tools/vasc_guard.sh $GOPATH/target/$projectname/$tag
    if [ -f $GOPATH/vpcm/project/$projectname/conf/nginx.conf ]; then
        cp $GOPATH/vpcm/project/$projectname/conf/nginx.conf $GOPATH/target/$projectname/$tag
        nginx_conf_path=`cat $GOPATH/vpcm/global/nginx_path.env`
    fi
    cd $GOPATH/target/
    tar -czf $projectname.tar.gz $projectname/$tag/
    scp -q $projectname.tar.gz $username@$hostname:$projectroot/$projectname.tar.gz
    ssh -qt $username@$hostname "cd $projectroot; tar -xf $projectroot/$projectname.tar.gz"
    ssh -qt $username@$hostname "rm -f $projectroot/$projectname.tar.gz"
    ssh -qt $username@$hostname "sudo bash $projectroot/$projectname/$tag/vasc_init.sh $projectname $tag $nginx_conf_path"
}

if [ "$#" -gt "2" ]; then
    echo "useage: vmt.sh <-b -p -g> <baseline>"
    exit 1
fi

action="build"
force_publish="no"

while [ $# -ge 1 ] ; do
    case "$1" in
        -b) baseline=$2; action=build; shift 2;;
        -p) baseline=$2; action=publish; shift 2;;
        -f) baseline=$2; action=publish; force_publish="yes"; shift 2;;
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
    echo -e "Do you want to publish this baseline?(yes/no):\c"
    read publish
    if [ "$publish" == "yes" ]; then
        action=publish
        baseline=$newbaseline
    else
        exit 0
    fi
fi

if [ "$action" == "publish" ]; then
    if [ ! -f $GOPATH/vpcm/global/service_root.env ]; then
        echo -e "\033[31mPublishing failed: cannot find $GOPATH/vpcm/global/service_root.env\033[0m"
        cd $cwd
        exit 1
    fi
    serviceroot=`cat $GOPATH/vpcm/global/service_root.env`
    hostlist=`cat $GOPATH/vpcm/global/host_list.scm`
    for hostname in $hostlist
    do
        echo "Checking $hostname..."
        ssh -tq $username@$hostname "mkdir -p $projectroot"
        ssh -tq $username@$hostname "sudo cp -f $serviceroot/baseline $projectroot/baseline"
        scp -q  $username@$hostname:$projectroot/baseline /tmp/baseline.$hostname
        ssh -tq $username@$hostname "sudo rm -f $projectroot/baseline"
        
        if [ ! -f /tmp/baseline.$hostname ]; then
            echo -e "\033[33mCannot fetch remote baseline for host:$hostname\033[0m"
            force_publish="yes"
        fi

        baselines=`cat $GOPATH/vpcm/baseline/$baseline`
        for line in $baselines
        do
            tag=${line##*/}
            projectname=${line%%/*}
            if [ "$force_publish" == "yes" ]; then
                echo -e "\033[33mForce publishing: $projectname: $tag\033[0m"
                publish_project $hostname $username $projectname $tag
            else
                remoteitem=`grep -E "^$projectname/" /tmp/baseline.$hostname`
                remotetag=${remoteitem##*/}
                if [ "$tag" != "$remotetag" ]; then
                    echo -e "\033[33m$projectname: $remotetag -> $tag\033[0m"
                    publish_project $hostname $username $projectname $tag
                fi
            fi
        done
        
        scp -q  $GOPATH/vpcm/baseline/$baseline $username@$hostname:$projectroot/baseline
        ssh -tq $username@$hostname "sudo mv -f $projectroot/baseline $serviceroot"
        rm -f /tmp/baseline.$hostname
        echo -e "\033[32mPublishing finished.\033[0m"
    done
    cd $cwd
fi

