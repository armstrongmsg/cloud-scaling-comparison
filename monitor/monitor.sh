#!/bin/bash

PROJECT_HOME="$SCALING_PROJECT_HOME"
CPU_LOG_FILE="$PROJECT_HOME/logs/monitor/monitor.log"

function log_cpu {
	echo "`date +%s%N` $1" >> $CPU_LOG_FILE
}

IFS=' '
read -r -a ips <<< "`cat $SCALING_PROJECT_HOME/conf/domain.properties | grep -v "#" | grep IP | awk 'BEGIN {ORS=" "} {print $2}'`"
read -r -a users <<< "`cat $SCALING_PROJECT_HOME/conf/domain.properties | grep -v "#" | grep user | awk 'BEGIN {ORS=" "} {print $2}'`"

while :
do
	for index in "${!ips[@]}"
	do
		IDLE="`$PROJECT_HOME/monitor/collector.sh ${users[$index]} ${ips[$index]}`"
		log_cpu "${ips[$index]} $IDLE"
	done
done
