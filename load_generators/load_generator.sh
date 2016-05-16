#!/bin/bash

GUEST_IP=$1
TIME_ADD_NEW_CLIENT=$2
MAX_CLIENTS=$3
CLIENT_SCRIPT="./client.sh"
CURRENT_CLIENTS=0

echo "Starting load generator"

while [ "$CURRENT_CLIENTS" -ne "$MAX_CLIENTS" ];
do	
	echo "Starting new client"
	$CLIENT_SCRIPT $GUEST_IP 2 &
	CURRENT_CLIENTS="$(($CURRENT_CLIENTS+1))"
	echo "Current number of clients: $CURRENT_CLIENTS"
	echo "Sleeping"
	sleep $TIME_ADD_NEW_CLIENT
done

pkill -P $$
