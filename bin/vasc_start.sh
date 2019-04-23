#!/bin/bash
servicepath=$1
serviceuser=$2
listenaddr=$3
profile=$4
projectname=$5

cmd="$servicepath/$projectname/$projectname -listen $listenaddr -pidfile $servicepath/$projectname/$projectname.pid -profile $profile 2>/dev/null&"

su - $serviceuser -c "$cmd"

