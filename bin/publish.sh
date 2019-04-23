#!/bin/bash

push_to_host() {
    projectname=$1
    hostname=$2
    username=$3
    listenaddr=$4

    echo "Deploying to $hostname..."
    scp ./$projectname.tar.gz $username@$hostname:~/$projectname.tar.gz
    echo "Extracting..."
    ssh -qt $username@$hostname "sudo tar -xf $projectname.tar.gz"
    ssh -qt $username@$hostname "rm -f $projectname.tar.gz"
    echo "Starting services..."
    ssh -qt $username@$hostname "sudo bash ./vasc_init.sh $environment $projectname $listenaddr"
    ssh -qt $username@$hostname "rm -f ./vasc_init.sh"
}

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

if [ -z "$projectname" ]; then
    echo "project_name cannot be empty"
    exit 1;
fi

if [ -z "$environment" ] ; then
    echo "environment cannot be empty"
    exit 1;
fi

#Assume the same user in remote host
username=`id -un`
serviceuser="mara"
servicerootpath="/home/mara"

listenaddr=`cat ./$projectname/config/listenaddr.$environment`

echo "Making package..."
make -s -C $projectname
tar -cf $projectname.tar ./$projectname/$projectname ./vasc_init.sh
gzip -f $projectname.tar
echo "Start transmission..."

if [ -z "$hostname" ]; then
    hosts=`cat ./config/hosts.$environment`
else
    array=(${hostname//,/ })
    hosts=${array[@]}
fi

for host in $hosts
do
    item=`echo $host | sed 's/^[ \t]*//g'`
    if [ "${item:0:1}" == "#" ]; then
        continue
    fi

    push_to_host $projectname $item $username $listenaddr
done

rm -f ./$projectname.tar.gz

