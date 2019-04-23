#!/bin/bash
servicepath="/home/mara/"
serviceuser="mara"
ngx_conf_path="/home/server_config/nginx/include/"
servicegroup=$serviceuser
profile=$1
projectname=$2

#Copy files into destnation path
tar -xf ./$projectname.tar.gz
rm -f ./$projectname.tar.gz
mkdir -p $servicepath/$projectname
chown $serviceuser:$servicegroup $servicepath/$projectname
chown -R $serviceuser:$servicegroup ./*

mv -f vasc_guard_driver.sh $servicepath
mv -f vasc_start.sh $servicepath/$projectname
mv -f vasc_stop.sh $servicepath/$projectname
mv -f vasc_guard.sh $servicepath/$projectname
mv -f vasc_switch.sh $servicepath/$projectname

mv -f ./$projectname/config/nginx_conf.$profile $servicepath/$projectname/nginx.conf
unlink $ngx_conf_path/$projectname.conf
ln -s $servicepath/$projectname/nginx.conf $ngx_conf_path/$projectname.conf
rm -fr ./$projectname

ret=`nginx -t 2>/dev/null`
if [ "$?" != "0" ]; then
    echo -e "\033[31mInvalid nginx conf\033[0m"
    exit 1
fi

