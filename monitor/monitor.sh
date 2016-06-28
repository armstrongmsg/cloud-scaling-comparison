#!/bin/bash

USER_IP="$1"
IP_TO_MONITOR="$2"
PROJECT_HOME="$SCALING_PROJECT_HOME"
CPU_LOG_FILE="$PROJECT_HOME/logs/monitor/monitor.$IP_TO_MONITOR.log"

function log_cpu {
	echo "`date +%s%N` $1" >> $CPU_LOG_FILE
}

while :
do
	IDLE="`$PROJECT_HOME/monitor/collector.sh $USER_IP $IP_TO_MONITOR`"
	log_cpu "$IDLE"
done
