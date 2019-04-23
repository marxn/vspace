#!/bin/bash

depoly_to_host() {
    projectname=$1
    hostname=$2
    username=$3
    
    echo "Deploying to $hostname..."
    scp ./$projectname.tar.gz $username@$hostname:~/$projectname.tar.gz
    echo "Extracting..."
    ssh -t $username@$hostname "sudo tar -xf $projectname.tar.gz"
    echo "Restarting nginx..."
    ssh -t $username@$hostname "sudo bash ./vasc_setup.sh $environment $projectname"

    if [ "$?" != "0" ]; then
        echo -e "\033[31mPublishing Failed! Check the nginx conf.\033[0m"
        exit 1
    fi

    ssh -t $username@$hostname "sudo /sbin/service nginx restart"
    ssh -t $username@$hostname "sudo rm -f ./vasc_setup.sh"
}

if [ $# -le 1 ];then
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
serviceuser="mara"
servicerootpath="/home/mara"

echo "Setup guard..."
./setup_guard.sh $environment
echo "Done."

echo "Making package..."
tar -cf $projectname.tar ./$projectname/config/nginx_conf.$environment ./vasc_start.sh ./vasc_stop.sh ./vasc_guard.sh ./vasc_setup.sh ./vasc_switch.sh ./vasc_guard_driver.sh
gzip -f $projectname.tar
rm -f ./vasc_guard_driver.sh
echo "Done. Start transmission..."

if [ -z "$hostname" ]; then
    hosts=`cat ./config/hosts.$environment`
else
    array=(${hostname//,/ })
    hosts=${array[@]}
fi

for hostname in $hosts
do
    depoly_to_host()
done

