#!/bin/bash
servicepath="/home/mara/"
serviceuser="mara"
servicegroup="mara"
profile=$1
projectname=$2
listenaddr=$3

#Generate a flag file in case of guard
touch $servicepath/$projectname/$projectname.up

#Copy new files into destnation path
mkdir -p $servicepath/$projectname
chmod +x ./$projectname/$projectname
chown $serviceuser:$servicegroup ./$projectname/$projectname

sha1ret=`sha1sum ./$projectname/$projectname`
servicedigest=${sha1ret%% *}

mv -f ./$projectname/$projectname $servicepath/$projectname/$projectname.$servicedigest
unlink $servicepath/$projectname/$projectname
ln -s $servicepath/$projectname/$projectname.$servicedigest $servicepath/$projectname/$projectname
rm -fr ./$projectname

timestamp=`date -d "now" '+%Y-%m-%d %H:%m:%S'`
echo -e "$timestamp $projectname.$servicedigest" >> $servicepath/$projectname/publish.log

#Stop service
bash $servicepath/$projectname/vasc_stop.sh $projectname $servicepath

#Restart service
bash $servicepath/$projectname/vasc_start.sh $servicepath $serviceuser $listenaddr $profile $projectname

#remove flag to enable guard
rm -f $servicepath/$projectname/$projectname.up
