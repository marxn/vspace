#!/bin/bash
profile=$1
serviceuser="mara"
servicepath="/home/mara/"

services=`cat ./config/service_list.$profile`

rm -f vasc_guard_driver.sh
echo "#!/bin/bash" > vasc_guard_driver.sh

for projectname in $services
do
    listenaddr=`cat $projectname/config/listenaddr.$profile`
    echo "$servicepath/$projectname/vasc_guard.sh $servicepath $serviceuser $listenaddr $profile $projectname" >> vasc_guard_driver.sh
done

chmod +x vasc_guard_driver.sh


