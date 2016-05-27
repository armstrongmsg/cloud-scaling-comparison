#!/bin/bash

WORKING_DIRECTORY="`dirname $0`"
GUEST_IP=$1
TIME_ADD_NEW_CLIENT=$2
MAX_CLIENTS=$3
CLIENT_SCRIPT=$WORKING_DIRECTORY"/client.sh"
CURRENT_CLIENTS=0

# TODO should handle the kill signal to kill the subprocesses
# TODO Log this
echo "Starting load generator"

while [ "$CURRENT_CLIENTS" -ne "$MAX_CLIENTS" ];
do	
	# TODO Log this
	echo "Starting new client"
	$CLIENT_SCRIPT $GUEST_IP 1 &
	CURRENT_CLIENTS="$(($CURRENT_CLIENTS+1))"
	# TODO Log this
	echo "Current number of clients: $CURRENT_CLIENTS"
	echo "Sleeping"
	sleep $TIME_ADD_NEW_CLIENT
done

pkill -P $$
