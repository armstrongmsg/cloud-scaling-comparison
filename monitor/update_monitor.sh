#!/bin/bash

IFS=' '
read -r -a ips <<< "`cat $SCALING_PROJECT_HOME/conf/domain.properties | grep -v "#" | grep IP | awk 'BEGIN {ORS=" "} {print $2}'`"
read -r -a users <<< "`cat $SCALING_PROJECT_HOME/conf/domain.properties | grep -v "#" | grep user | awk 'BEGIN {ORS=" "} {print $2}'`"

for index in "${!ips[@]}"
do
	if [ ! -e "$SCALING_PROJECT_HOME/logs/monitor/pids/monitor.${ips[$index]}.pid" ]; then
		echo "Starting monitoring for ip ${ips[$index]}"
		"$SCALING_PROJECT_HOME/monitor/monitor.sh" ${users[$index]} ${ips[$index]} &
		echo $! > "$SCALING_PROJECT_HOME/logs/monitor/pids/monitor.${ips[$index]}.pid"
	fi
done
