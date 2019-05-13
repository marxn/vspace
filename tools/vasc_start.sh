#!/bin/bash
servicepath=$1
serviceuser=$2
projectname=$3

cmd="$servicepath/$projectname/$projectname -n $projectname -p $servicepath/$projectname/$projectname.pid 1>$servicepath/$projectname/console.log 2>&1 &"
su - $serviceuser -c "$cmd"

