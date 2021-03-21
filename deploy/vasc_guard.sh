#!/bin/bash
servicepath=$1
serviceuser=$2
profile=$3
baselinepath=$4
baseline=`cat $baselinepath/baseline`

for line in $baseline
do
    tag=${line##*/}
    projectname=${line%%/*}

    if [ -f "$servicepath/$projectname.up" ];then
        continue
    fi

    if [ ! -f "$servicepath/$projectname/$projectname.pid" ];then
        continue
    fi

    pid=`cat $servicepath/$projectname/$projectname.pid`
    RESULT=`ps -efq $pid | grep $pid`
    if [ -z "$RESULT" ];then
        echo -e "$projectname process crashed. attempt to restart..."
        $servicepath/$projectname/${projectname}_start.sh $servicepath $serviceuser $projectname $profile
    fi
done

