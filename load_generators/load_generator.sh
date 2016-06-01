#!/bin/bash

PROJECT_HOME=$SCALING_PROJECT_HOME
GUEST_IP=$1
TIME_ADD_NEW_CLIENT=$2
MAX_CLIENTS=$3
CLIENT_WAIT_TIME=$4
CLIENT_SCRIPT=$PROJECT_HOME"/load_generators/client.sh"
CURRENT_CLIENTS=0
LOAD_GENERATOR_LOG_FILE=$PROJECT_HOME"/logs/load_generator.log"

function log {
	echo "`date +%s%N` $1" >> $LOAD_GENERATOR_LOG_FILE
}

# TODO should handle the kill signal to kill the subprocesses
log "Starting load generator"

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

log "Stopping clients"

pkill -P $$
