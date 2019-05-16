#!/bin/bash
servicepath="/home/mara/"
serviceuser="mara"
servicegroup="mara"
projectroot="./project"
projectname=$1
version=$2
nginx_conf_path=$3
publish_token=$4

#Generate a flag file in case of guard
touch $servicepath/$projectname/$projectname.up

source="$projectroot/$projectname/$version/"

unlink $servicepath/$projectname/$projectname
if [ -d $servicepath/$projectname/$version ]; then
    version=$version-$publish_token
fi

mkdir -p $servicepath/$projectname/$version
cp -R $source/* $servicepath/$projectname/$version
ln -s $servicepath/$projectname/$version/$projectname $servicepath/$projectname/$projectname

chown -R $serviceuser:$servicegroup  $servicepath/$projectname
chmod +x $source/$projectname

mv -f $servicepath/$projectname/$version/vasc_guard.sh $servicepath
mv -f $servicepath/$projectname/$version/vasc_start.sh $servicepath
mv -f $servicepath/$projectname/$version/vasc_stop.sh $servicepath
rm -fr $projectroot/$projectname

#Stop service
bash $servicepath/vasc_stop.sh $projectname $servicepath

#Restart service
bash $servicepath/vasc_start.sh $servicepath $serviceuser $projectname

if [ "$nginx_conf_path" != "" ]; then
    origin_conf_link=`readlink $nginx_conf_path/$projectname.conf`
    unlink $nginx_conf_path/$projectname.conf
    ln -s $servicepath/$projectname/$version/nginx.conf $nginx_conf_path/$projectname.conf
    ret=`nginx -t 2>/dev/null`
    if [ "$?" != "0" ]; then
        echo -e "\033[31mInvalid nginx conf, publish $projectname failed. Check nginx config file then try again\033[0m"
        ln -s $origin_conf_link $nginx_conf_path/$projectname.conf
        exit 1
    fi
fi

#remove flag to enable guard
rm -f $servicepath/$projectname/$projectname.up
