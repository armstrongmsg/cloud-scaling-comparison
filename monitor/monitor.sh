#!/bin/bash

USER_IP="$1"
IP_TO_MONITOR="$2"
PROJECT_HOME="$SCALING_PROJECT_HOME"
CPU_LOG_FILE="$PROJECT_HOME/logs/monitor/monitor.$IP_TO_MONITOR.log"
ERROR_LOG_FILE="$PROJECT_HOME/logs/monitor/monitor.error"

function log_cpu {
	echo "`date +%s%N` $1" >> $CPU_LOG_FILE
}

function log_error {
	echo "`date +%s%N` $1" >> $ERROR_LOG_FILE
}

if [ $# -ne 2 ]
then
	log_error "Incorrect number of arguments ($#)."
	exit 1
fi 

if [ -z "$USER_IP" ]
then
	log_error "USER_IP is empty. Exiting."
	exit 1
elif [ -z "$IP_TO_MONITOR" ]
then
	log_error "IP_TO_MONITOR is empty. Exiting."
	exit 1
fi

while :
do
	IDLE="`$PROJECT_HOME/monitor/collector.sh $USER_IP $IP_TO_MONITOR`"
	log_cpu "$IDLE"
done
