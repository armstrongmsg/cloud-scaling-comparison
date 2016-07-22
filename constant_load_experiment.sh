#!/bin/bash

N_CLIENTS=40
LOAD_BALANCER_IP="192.168.122.90"
CLIENT_WAIT_TIME=1
LOAD_BALANCER_USER="armstrong"
# for CPU cap and N CPUs
#SCALING_WAIT_TIME=20
# for vms
SCALING_WAIT_TIME=150
SCALING_TYPE="VMs"
VM_NAME="lubuntu1"
MAIN_DOMAIN_IP="`cat $SCALING_PROJECT_HOME/conf/domain.properties | grep -v "#" | grep IP | awk 'FNR == 2 {print $2}'`"
MAIN_DOMAIN_USER="armstrong"

function clean_up {
        echo "Stopping clients"
        pkill -P $$
        exit 0
}

trap clean_up SIGINT SIGTERM

echo "starting clients"
for client in `seq 1 $N_CLIENTS`
do
	"$SCALING_PROJECT_HOME/load_generators/client.sh" $client $LOAD_BALANCER_IP $CLIENT_WAIT_TIME &
done

echo "starting monitors"
"$SCALING_PROJECT_HOME/monitor/monitor.sh" $MAIN_DOMAIN_USER $MAIN_DOMAIN_IP &

echo "sleeping"
sleep $SCALING_WAIT_TIME

for scaling_index in `seq 1 3`
do
	echo "scaling"
	"$SCALING_PROJECT_HOME/scaling/scaling.sh" $SCALING_TYPE $VM_NAME $LOAD_BALANCER_IP
	echo "sleeping"
	sleep $SCALING_WAIT_TIME
done

clean_up
