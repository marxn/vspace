#!/bin/bash
projectname=$1
servicepath=$2

pid=`cat $servicepath/$projectname/$projectname.pid`
kill -s SIGUSR1 $pid
while true
do
	RESULT=`ps -efq $pid|grep '$projectname'|grep $pid`
	if [ -z "$RESULT" ];then
		break
	fi
	sleep 1
done
