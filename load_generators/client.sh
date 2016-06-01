#!/bin/bash

ID=$1
GUEST_IP=$2
WAIT_TIME=$3
APPLICATION="server.php"
PROJECT_HOME=$SCALING_PROJECT_HOME
REQUESTS_LOG_FILE="$PROJECT_HOME/logs/clients/requests.$ID.log"
CLIENT_LOG_FILE="$PROJECT_HOME/logs/clients/client.$ID.log"

function log_generic {
	echo $1 >> $2
}

function log_request {
	log_generic "$1-$2" $REQUESTS_LOG_FILE
}

function log {
	log_generic "`date +%s%N` $1" $CLIENT_LOG_FILE
}

log "Starting client..."

while [ 1 = 1 ];
do
	log "Going to sleep"
	sleep $WAIT_TIME
	log "Waking up"
	log "Accessing application"
	START_TIME=`date +%s%N`
	curl -s $GUEST_IP/$APPLICATION
	END_TIME=`date +%s%N`
	REQUEST_TIME=$(echo "$END_TIME - $START_TIME" | bc)
	log_request $END_TIME $REQUEST_TIME
done
