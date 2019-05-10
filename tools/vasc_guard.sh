servicepath=$1
serviceuser=$2
projectname=$3
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
            $projectpath/vasc_start.sh $servicepath $serviceuser $projectname
fi

