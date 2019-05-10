#!/bin/bash
servicepath="/home/mara/"
serviceuser="mara"
servicegroup="mara"
projectroot="./project"
projectname=$1
version=$2

#Generate a flag file in case of guard
touch $servicepath/$projectname/$projectname.up

#Copy new files into destnation path
source="$projectroot/$projectname/$version/"

unlink $servicepath/$projectname/$projectname
if [ -d $servicepath/$projectname/$version ]; then
    rm -fr $servicepath/$projectname/$version
fi

mkdir -p $servicepath/$projectname/$version
cp -R $source/* $servicepath/$projectname/$version
ln -s $servicepath/$projectname/$version/$projectname $servicepath/$projectname/$projectname

chown -R $serviceuser:$servicegroup  $servicepath/$projectname
chmod +x $source/$projectname

mv -f $servicepath/$projectname/$version/*.sh $servicepath/$projectname/

rm -fr $projectroot/$projectname

#Stop service
bash $servicepath/$projectname/vasc_stop.sh $projectname $servicepath

#Restart service
bash $servicepath/$projectname/vasc_start.sh $servicepath $serviceuser $projectname

#remove flag to enable guard
rm -f $servicepath/$projectname/$projectname.up
