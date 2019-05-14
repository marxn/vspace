#!/bin/bash
serviceroot=$1
serviceuser=$2

baseline=`cat $serviceroot/baseline`

for line in $baseline
do
    tag=${line##*/}
    projectname=${line%%/*}
    if [ ! -f $serviceroot/$projectname/vasc_guard.sh ]; then
        exit 1
    fi
    $serviceroot/$projectname/vasc_guard.sh $serviceroot $serviceuser $projectname
done

