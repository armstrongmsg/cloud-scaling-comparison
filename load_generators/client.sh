#!/bin/bash

GUEST_IP=$1
WAIT_TIME=$2
APPLICATION="server.php"

# TODO log this
echo "Starting client..."

while [ 1 = 1 ];
do
	# TODO log this
	echo "Going to sleep"
	sleep $WAIT_TIME
	# TODO log this
	echo "Waking up"
	echo "Accessing application"	
	# TODO time this request and log it
	curl $GUEST_IP/$APPLICATION
done
