servicepath=$1
serviceuser=$2
listenaddr=$3
profile=$4
projectname=$5
projectpath=$servicepath/$projectname

if [ -f "$servicepath/$projectname/$projectname.up" ];then
    exit
fi

if [ ! -f "$servicepath/$projectname/$projectname.pid" ];then
    exit
fi

pid=`cat $servicepath/$projectname//$projectname.pid`
RESULT=`ps -efq $pid | grep $pid`
if [ -z "$RESULT" ];then
            echo -e "$projectname process crashed. attempt to restart..."
            $projectpath/vasc_start.sh $servicepath $serviceuser $listenaddr $profile $projectname
fi

