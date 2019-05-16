#!/bin/bash
#Vspace Manufacture Tool
username=`id -un`
projectroot="$HOME/project"

publish_project() {
    hostname=$1
    username=$2
    projectname=$3
    tag=$4
    nginx_conf_path=""
    token=`cat /proc/sys/kernel/random/uuid`

    cp $GOPATH/deploy/*.sh $GOPATH/target/$projectname/$tag
    if [ -f $GOPATH/vpcm/project/$projectname/conf/nginx.conf ]; then
        cp $GOPATH/vpcm/project/$projectname/conf/nginx.conf $GOPATH/target/$projectname/$tag
        nginx_conf_path=`cat $GOPATH/vpcm/global/nginx_path.env`
    fi
    cd $GOPATH/target/
    tar -czf $projectname.tar.gz $projectname/$tag/
    scp -q $projectname.tar.gz $username@$hostname:$projectroot/$projectname.tar.gz
    ssh -qt $username@$hostname "cd $projectroot; tar -xf $projectroot/$projectname.tar.gz; rm -f $projectroot/$projectname.tar.gz"
    ssh -qt $username@$hostname "sudo bash $projectroot/$projectname/$tag/vasc_init.sh \"$projectname\" \"$tag\" \"$nginx_conf_path\" \"$token\""
    rm -f $projectname.tar.gz
}

action=""
force_publish="no"

while [ $# -ge 1 ] ; do
    case "$1" in
        -p) baseline=$2; action=publish; shift 2;;
        -f) baseline=$2; action=publish; force_publish="yes"; shift 2;;
        -g) baseline=$2; action=generate; shift 1;;
         *) echo "unknown parameter $1." ; exit 1 ; break;;
    esac
done

if [ "$action" == "" ]; then
    echo "usage: vmt.sh <-g -p -f> [<baseline>]"
    echo "Example: vmt.sh -g [baseline]   Generate a new baseline for all projects controlled in vpcm."
    echo "Example: vmt.sh -p <baseline>   Publish the baseline"
    echo "Example: vmt.sh -f <baseline>   Publish the baseline(by force)"
    exit 1
fi

cwd=`pwd`

if [ "$action" == "generate" ]; then
    cd $GOPATH/vpcm/
    git pull
    cd $cwd

    if [ "$baseline" == "" ]; then
        uuid=`cat /proc/sys/kernel/random/uuid`
        timestamp=`date -d "now" '+%Y%m%d-%H%M%S'`
        newbaseline="$timestamp--$uuid"
    else
        newbaseline=$baseline
    fi
    touch $GOPATH/unstamped.txt
    while read line
    do
        projectname=${line%% *}
        address=${line##* }
        echo "Checking version for $projectname..."
        if [ ! -d $GOPATH/src/$projectname ]; then
            echo -e "\033[33mCannot find source code directory for project:$projectname. Try to check it out...\033[0m"
            cd $GOPATH/src
            git clone $address $projectname
            if [ "$?" != "0" ]; then
                echo -e "\033[31mCannot check out project:$projectname.\033[0m"
                exit 1
            fi
        fi
        cd $GOPATH/src/$projectname
        changed_files=`git diff --name-only`
        if [ "$changed_files" != "" ]; then
            echo -e "\033[31mProject [$projectname] has files to be commited:\n$changed_files\033[0m"
            exit 1
        fi

        if [ ! -f "$GOPATH/src/$projectname/version.txt" ]; then
            echo -e "\033[31mCannot find source code version.txt for project:$projectname\033[0m"
            exit 1
        fi
        tag=`cat $GOPATH/src/$projectname/version.txt`
        if [ "$tag" == "" ]; then
            echo -e "\033[31mEmpty version.txt for project:$projectname\033[0m"
            exit 1
        fi

        unstamped=`git diff --stat $tag HEAD`
        if [ "$unstamped" != "" ]; then
            echo "$projectname" >> $GOPATH/unstamped.txt
        fi
        echo "$projectname/$tag" >> $GOPATH/vpcm/baseline/$newbaseline
    done < $GOPATH/vpcm/global/project_list.scm

    unstamped_project=`cat $GOPATH/unstamped.txt`
    rm -f $GOPATH/unstamped.txt
    if [ "$unstamped_project" != "" ]; then
        echo -e "\033[33mFollowing project(s) seems do not have a new version since last modification:\n$unstamped_project\033[0m"
        read -p "Do you insist to continue?(yes/no):" iscontinue
        if [ "$iscontinue" != "yes" ]; then
            rm -f $GOPATH/vpcm/baseline/$newbaseline
            exit 1
        fi
    fi

    echo -e "\033[32mGenerating new baseline successfully.\nNew baseline: $newbaseline\033[0m"
    read -p "Do you want to commit this baseline?(yes/no):" commit
    if [ "$commit" == "yes" ]; then
        cd $GOPATH/vpcm/baseline/
        git add $newbaseline
        git commit -m "$newbaseline"
        git push
        cd $cwd
    fi
fi

if [ "$action" == "publish" ]; then
    has_published_project="0"
    if [ "$baseline" == "" ]; then
        echo -e "Baseline must be identified"
        exit 1
    fi

    cd $GOPATH/vpcm
    git pull
    cd $GOPATH/vpcm/baseline
    git pull
    cd $cwd

    if [ ! -f $GOPATH/vpcm/global/service_root.env ]; then
        echo -e "\033[31mPublishing failed: cannot find $GOPATH/vpcm/global/service_root.env\033[0m"
        exit 1
    fi
    serviceroot=`cat $GOPATH/vpcm/global/service_root.env`
    if [ "$serviceroot" == "" ]; then
        echo -e "\033[31mPublishing failed: cannot find any content in $GOPATH/vpcm/global/service_root.env\033[0m"
        exit 1
    fi

    if [ ! -f $GOPATH/vpcm/global/service_user.env ]; then
        echo -e "\033[31mPublishing failed: cannot find $GOPATH/vpcm/global/service_user.env\033[0m"
        exit 1
    fi
    serviceuser=`cat $GOPATH/vpcm/global/service_user.env`
    if [ "$serviceuser" == "" ]; then
        echo -e "\033[31mPublishing failed: cannot find any content in $GOPATH/vpcm/global/service_user.env\033[0m"
        exit 1
    fi

    if [ ! -f $GOPATH/vpcm/global/service_group.env ]; then
        echo -e "\033[31mPublishing failed: cannot find $GOPATH/vpcm/global/service_group.env\033[0m"
        exit 1
    fi
    servicegroup=`cat $GOPATH/vpcm/global/service_group.env`
    if [ "$servicegroup" == "" ]; then
        echo -e "\033[31mPublishing failed: cannot find any content in $GOPATH/vpcm/global/service_group.env\033[0m"
        exit 1
    fi

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

            packagepath=$GOPATH/target/$projectname/$tag

            if [ ! -d "$packagepath" ]; then
                ./build.sh -p $projectname -t $tag
                if [ "$?" != "0" ]; then
                    echo -e "\033[31mCannot build $projectname/$tag.\033[0m"
                    exit 1
                fi
            fi

            if [ "$force_publish" == "yes" ]; then
                echo -e "\033[33mForce publishing: $projectname: $tag\033[0m"
                publish_project $hostname $username $projectname $tag
                has_published_project="1"
            else
                remoteitem=`grep -E "^$projectname/" /tmp/baseline.$hostname`
                remotetag=${remoteitem##*/}
                if [ "$tag" != "$remotetag" ]; then
                    echo -e "\033[33m$projectname: $remotetag -> $tag\033[0m"
                    publish_project $hostname $username $projectname $tag
                    has_published_project="1"
                fi
            fi
        done
        cd $cwd
        scp -q  $GOPATH/vpcm/baseline/$baseline $username@$hostname:$projectroot/baseline
        ssh -tq $username@$hostname "sudo mv -f $projectroot/baseline $serviceroot; sudo chown $serviceuser:$servicegroup $serviceroot/baseline"
        if [ "$has_published_project" == "1" ]; then
            ssh -tq $username@$hostname "sudo /sbin/service nginx restart"
        fi
        rm -f /tmp/baseline.$hostname
    done
    echo -e "\033[32mPublishing finished.\033[0m"
fi

