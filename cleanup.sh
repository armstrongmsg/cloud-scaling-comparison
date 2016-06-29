#!/bin/bash

LOGS_DIRECTORY="$SCALING_PROJECT_HOME/logs"

#
# Backup logs, pids and conf
#

cd "$SCALING_PROJECT_HOME"
zip -r "results/results-`date +%Y-%m-%d-%H-%M-%S`.zip" "logs" "conf"

# 
# Remove logs and pids
#

# Remove pids
echo "Removing alarm and load generator pids"
rm "$LOGS_DIRECTORY/"*pid
rm "$LOGS_DIRECTORY/monitor/pids/"*pid

# Remove logs
echo "Remove monitor logs"
rm "$LOGS_DIRECTORY/monitor/"*log

echo "Remove scaling logs"
rm "$LOGS_DIRECTORY/scaling/"*log

echo "Remove clients logs"
rm "$LOGS_DIRECTORY/clients/"*log

echo "Remove load generators logs"
rm "$LOGS_DIRECTORY/load_generators/"*log
rm "$LOGS_DIRECTORY/load_generator.log"

# Remove error logs
echo "Remove monitor error logs"
rm "$LOGS_DIRECTORY/monitor/"*error

echo "Remove scaling error logs"
rm "$LOGS_DIRECTORY/scaling/"*error

echo "Remove load generators error logs"
rm "$LOGS_DIRECTORY/load_generators/"*error

echo "Remove curl error logs"
rm "$LOGS_DIRECTORY/curl.error"

#
# Delete the created VMs
#

# Assuming that the two first VMs are the load balancer and the base computing node
read -r -a vms <<< `cat $SCALING_PROJECT_HOME/conf/domain.properties | grep -v "#" | grep "\[" |  sed 's/.*\[//;s/\].*//;'`

VMS_DIRECTORY=/local/VMs

for index in `seq 2 $((${#vms[@]}-1))`
do
	echo "Stopping VM ${vms[$index]}"
	virsh destroy ${vms[$index]} --graceful
	echo "Undefining VM ${vms[$index]}"
	virsh undefine ${vms[$index]}
	echo  "Deleting storage ${vms[$index]}"
	rm -f "$VMS_DIRECTORY/${vms[$index]}"
done

#
# Restore the configuration
#

IFS=' '
read -r -a ips <<< "`cat $SCALING_PROJECT_HOME/conf/domain.properties | grep -v "#" | grep IP | awk 'BEGIN {ORS=" "} {print $2}'`"
read -r -a users <<< "`cat $SCALING_PROJECT_HOME/conf/domain.properties | grep -v "#" | grep user | awk 'BEGIN {ORS=" "} {print $2}'`"

LOAD_BALANCER_IP="${ips[0]}"
LOAD_BALANCER_USER="${users[0]}"

echo "Restoring load balancer configuration"
ssh $LOAD_BALANCER_USER@$LOAD_BALANCER_IP cp haproxy.bak haproxy.cfg
echo "Restarting load balancer"
ssh root@$LOAD_BALANCER_IP service haproxy restart

echo "Restarting domain configuration"
cp "$SCALING_PROJECT_HOME/backup/domain.properties" "$SCALING_PROJECT_HOME/conf"

