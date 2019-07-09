#!/bin/bash
servicepath=$1
serviceuser=$2
profile=$3

baseline=`cat $servicepath/baseline`

for line in $baseline
do
    tag=${line##*/}
    projectname=${line%%/*}

    if [ -f "$servicepath/$projectname.up" ];then
        exit 0
    fi

    if [ ! -f "$servicepath/$projectname/$projectname.pid" ];then
        exit 1
    fi

    pid=`cat $servicepath/$projectname/$projectname.pid`
    RESULT=`ps -efq $pid | grep $pid`
    if [ -z "$RESULT" ];then
        echo -e "$projectname process crashed. attempt to restart..."
        $servicepath/vasc_start.sh $servicepath $serviceuser $projectname $profile
    fi
done

