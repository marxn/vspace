#!/bin/bash
servicepath=$1
serviceuser=$2
projectname=$3

cmd="$servicepath/$projectname/$projectname -n $projectname -p $servicepath/$projectname/$projectname.pid 2>/dev/null&"
su - $serviceuser -c "$cmd"

