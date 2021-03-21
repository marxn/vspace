#!/bin/bash
projectname=$1
servicepath=$2

if [ ! -f $servicepath/$projectname/$projectname.pid ]; then
	exit 0
fi

pid=`cat $servicepath/$projectname/$projectname.pid`
if [ "$pid" == "" ]; then
	exit 1
fi

kill -s SIGINT $pid
while true
do
	RESULT=`ps -efq $pid|grep '$projectname'|grep $pid`
	if [ -z "$RESULT" ];then
		break
	fi
	sleep 1
done
