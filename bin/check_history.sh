#!/bin/bash

if [ $# -le 3 ];then
    echo "$0 -p <project_name> -e <environment> [-h <host1>,<host2>...]"
    exit 1;
fi

while [ $# -ge 2 ] ; do
    case "$1" in
        -p) projectname=$2; shift 2;;
        -e) environment=$2; shift 2;;
        -h) hostname=$2; shift 2;;
         *) echo "unknown parameter $1." ; exit 1 ; break;;
    esac
done

username=`id -un`
hosts=`cat ./config/hosts.$environment`
serviceuser="mara"
servicerootpath="/home/mara"

#Make current binary
make -s -C $projectname 1>/dev/null 2>&1

baseline=`sha1sum $projectname/$projectname`
echo "$projectname Baseline: $baseline"

if [ -z "$hostname" ]; then
    hosts=`cat ./config/hosts.$environment`
else
    array=(${hostname//,/ })
    hosts=${array[@]}
    if [ -z "hosts" ]; then
        exit 1 ;
    fi
fi

for hostname in $hosts
do
    echo "Checking $hostname..."
    ssh -qt $username@$hostname "sudo cat $servicerootpath/$projectname/publish.log"
done

