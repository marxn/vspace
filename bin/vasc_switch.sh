#!/bin/bash
servicepath="/home/mara/"
serviceuser="mara"
servicegroup="mara"
profile=$1
projectname=$2
listenaddr=$3
version=$4

#Generate a flag file in case of guard
touch $servicepath/$projectname/$projectname.up

unlink $servicepath/$projectname/$projectname
ln -s $servicepath/$projectname/$projectname.$version $servicepath/$projectname/$projectname

#Stop service
bash $servicepath/$projectname/vasc_stop.sh $projectname $servicepath

#Restart service
bash $servicepath/$projectname/vasc_start.sh $servicepath $serviceuser $listenaddr $profile $projectname

#remove flag to enable guard
rm -f $servicepath/$projectname/$projectname.up
