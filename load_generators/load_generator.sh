#!/bin/bash

PROJECT_HOME=$SCALING_PROJECT_HOME
GUEST_IP=$1
TIME_ADD_NEW_CLIENT=$2
MAX_CLIENTS=$3
CLIENT_WAIT_TIME=$4
CLIENT_SCRIPT=$PROJECT_HOME"/load_generators/client.sh"
CURRENT_CLIENTS=0
LOAD_GENERATOR_LOG_FILE=$PROJECT_HOME"/logs/load_generator.log"
ERROR_LOG_FILE="$PROJECT_HOME/logs/load_generators/load_generator.error"

function log {
	echo "`date +%s%N` $1" >> $LOAD_GENERATOR_LOG_FILE
}

function log_error {
	echo "`date +%s%N` $1" >> $ERROR_LOG_FILE
}

function clean_up {
	log "Stopping clients"
	pkill -P $$
	exit 0
}

trap clean_up SIGINT SIGTERM

# Check arguments
if [ $# -ne 4 ]
then
	log_error "Incorrect number of arguments ($#). Exiting"
	exit 1
fi

if [ -z $GUEST_IP ]
then
	log_error "GUEST_IP is empty. Exiting."
	exit 1
elif [ -z $TIME_ADD_NEW_CLIENT ]
then
	log_error "TIME_ADD_NEW_CLIENT is empty. Exiting."
	exit 1
elif [ -z $MAX_CLIENTS ]
then
	log_error "MAX_CLIENTS is empty. Exiting."
	exit 1
elif [ -z $CLIENT_WAIT_TIME ]
then
	log_error "CLIENT_WAIT_TIME is empty. Exiting."
fi

log "guest ip: $GUEST_IP"
log "time add new client: $TIME_ADD_NEW_CLIENT"
log "max clients: $MAX_CLIENTS"
log "client wait time: $CLIENT_WAIT_TIME"
log "Starting load generator"
log ""

while [ "$CURRENT_CLIENTS" -ne "$MAX_CLIENTS" ];
do	
	CLIENT_ID=$CURRENT_CLIENTS
	log "Starting new client. ID:$CLIENT_ID"
	$CLIENT_SCRIPT $CLIENT_ID $GUEST_IP $CLIENT_WAIT_TIME &
	CURRENT_CLIENTS="$(($CURRENT_CLIENTS+1))"
	log "Current number of clients: $CURRENT_CLIENTS"
	log  "Sleeping"
	sleep $TIME_ADD_NEW_CLIENT
done

clean_up
