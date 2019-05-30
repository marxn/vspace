#!/bin/bash
servicepath=$1
serviceuser=$2
servicegroup=$3
projectroot="./project"
projectname=$4
version=$5
nginx_conf_path=$6
environment=$7
publish_token=$8

#Generate a flag file in case of guard
#mkdir -p $servicepath/$projectname/
touch $servicepath/$projectname.up

source="$projectroot/$projectname/$version/"

if [ -d $servicepath/pkgs/$projectname/$version ]; then
    version=$version-$publish_token
fi

mkdir -p $servicepath/pkgs/$projectname/$version
cp -R $source/* $servicepath/pkgs/$projectname/$version
chown -R $serviceuser:$servicegroup $servicepath/

unlink $servicepath/$projectname
ln -s $servicepath/pkgs/$projectname/$version $servicepath/$projectname

#for those projects built by golang or other language which generated a executable file
if [ -f $source/$projectname ]; then
    mv -f $servicepath/pkgs/$projectname/$version/vasc_guard.sh $servicepath
    mv -f $servicepath/pkgs/$projectname/$version/vasc_start.sh $servicepath
    mv -f $servicepath/pkgs/$projectname/$version/vasc_stop.sh $servicepath

    #Stop service
    bash $servicepath/vasc_stop.sh $projectname $servicepath

    #Restart service
    bash $servicepath/vasc_start.sh $servicepath $serviceuser $projectname
fi
rm -fr $projectroot/$projectname

if [ "$nginx_conf_path" != "" ]; then
    if [ -L $nginx_conf_path/vspace-$projectname-$serviceuser.conf ]; then
        origin_conf_link=`readlink $nginx_conf_path/vspace-$projectname-$serviceuser.conf`
        unlink $nginx_conf_path/vspace-$projectname-$serviceuser.conf
    fi
    ln -s $servicepath/pkgs/$projectname/$version/nginx.conf $nginx_conf_path/vspace-$projectname-$serviceuser.conf
    ret=`nginx -t 2>/dev/null`
    if [ "$?" != "0" ]; then
        echo -e "\033[31mInvalid nginx conf, publish $projectname failed. Check nginx config file then try again\033[0m"
        if [ "$origin_conf_link" != "" ]; then
            unlink $nginx_conf_path/vspace-$projectname-$serviceuser.conf
            ln -s $origin_conf_link $nginx_conf_path/vspace-$projectname-$serviceuser.conf
        fi
        exit 1
    fi
fi

#remove flag to enable guard
rm -f $servicepath/$projectname.up
