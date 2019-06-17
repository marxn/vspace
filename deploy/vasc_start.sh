#!/bin/bash
servicepath=$1
serviceuser=$2
projectname=$3
environment=$4

cmd="$servicepath/$projectname/$projectname -n $projectname -e $environment -p $servicepath/$projectname/$projectname.pid 1>$servicepath/$projectname/console.log 2>&1 &"
su - $serviceuser -c "$cmd"

