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
mkdir -p $servicepath/$projectname
touch $servicepath/$projectname/$projectname.up

source="$projectroot/$projectname/$version/"

if [ -d $servicepath/$projectname/$version ]; then
    version=$version-$publish_token
fi

mkdir -p $servicepath/$projectname/$version
cp -R $source/* $servicepath/$projectname/$version
chown -R $serviceuser:$servicegroup $servicepath/$projectname

#for those projects built by golang or other language which generated a executable file
if [ -f $source/$projectname ]; then
    unlink $servicepath/$projectname/$projectname
    ln -s $servicepath/$projectname/$version/$projectname $servicepath/$projectname/$projectname
    mv -f $servicepath/$projectname/$version/vasc_guard.sh $servicepath
    mv -f $servicepath/$projectname/$version/vasc_start.sh $servicepath
    mv -f $servicepath/$projectname/$version/vasc_stop.sh $servicepath
    rm -fr $projectroot/$projectname
    
    #Stop service
    bash $servicepath/vasc_stop.sh $projectname $servicepath

    #Restart service
    bash $servicepath/vasc_start.sh $servicepath $serviceuser $projectname
else
    #for f-end pages
    if [ -d $servicepath/$projectname/$version/dist ]; then
        if [ -L $servicepath/$projectname/dist ]; then
            unlink $servicepath/$projectname/dist
        fi
        ln -s $servicepath/$projectname/$version/dist $servicepath/$projectname/dist
    fi
fi

if [ "$nginx_conf_path" != "" ]; then
    if [ -L $nginx_conf_path/$projectname.conf ]; then
        origin_conf_link=`readlink $nginx_conf_path/$projectname.conf`
        unlink $nginx_conf_path/$projectname.conf
    fi
    ln -s $servicepath/$projectname/$version/nginx.conf $nginx_conf_path/$projectname.conf
    ret=`nginx -t 2>/dev/null`
    if [ "$?" != "0" ]; then
        echo -e "\033[31mInvalid nginx conf, publish $projectname failed. Check nginx config file then try again\033[0m"
        if [ "$origin_conf_link" != "" ]; then
            ln -s $origin_conf_link $nginx_conf_path/$projectname.conf
        fi
        exit 1
    fi
fi

#remove flag to enable guard
rm -f $servicepath/$projectname/$projectname.up
