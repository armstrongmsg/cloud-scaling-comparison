#!/bin/bash

GUEST_IP=$1
WAIT_TIME=$2
APPLICATION="server.php"

echo "Starting client..."

while [ 1 = 1 ];
do
	echo "Going to sleep"
	sleep $WAIT_TIME
	echo "Waking up"
	echo "Accessing application"	
	curl $GUEST_IP/$APPLICATION
done
