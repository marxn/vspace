#!/bin/bash

if [ $# -le 1 ];then
    echo "$0 -p <project_name> -e <environment> -v version [-h <host1>,<host2>...]"
    exit 1;
fi

while [ $# -ge 5 ] ; do
    case "$1" in
        -p) projectname=$2; shift 2;;
        -e) environment=$2; shift 2;;
        -v) version=$2; shift 2;;
        -h) hostname=$2; shift 2;;
         *) echo "unknown parameter $1." ; exit 1 ; break;;
    esac
done

username=`id -un`
listenaddr=`cat ./$projectname/config/listenaddr.$environment`
serviceuser="mara"
servicerootpath="/home/mara"

if [ -z "$hostname" ]; then
    hosts=`cat ./config/hosts.$environment`
else
    array=(${hostname//,/ })
    hosts=${array[@]}
fi

for hostname in $hosts
do
    echo "Switching version on $hostname..."
    ssh -qt $username@$hostname "sudo bash $servicerootpath/$projectname/vasc_switch.sh $environment $projectname $listenaddr $version"
done

