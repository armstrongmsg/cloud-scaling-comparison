#!/bin/bash

# check required environment variables
: "${SCALING_PROJECT_HOME:?Need to set SCALING_PROJECT_HOME non-empty}"

# check required programs
DEPENDENCIES="python virsh curl"

for program in $DEPENDENCIES; do
	hash $program 2>/dev/null || { echo >&2 "I require $program but it's not installed.  Aborting."; exit 1; }
done

# check log directories
LOG_DIRECTORIES="logs logs/scaling logs/load_generators logs/monitor logs/clients logs/monitor/pids"

for directory in $LOG_DIRECTORIES; do
	if [ ! -d "$SCALING_PROJECT_HOME/$directory" ]; then
		mkdir "$SCALING_PROJECT_HOME/$directory"
	fi
done

# check all scripts are placed correctly
SCRIPT_FILES="load_generators/client.sh load_generators/load_generator.sh monitor/alarm.py monitor/collector.sh monitor/monitor.sh monitor/update_monitor.sh scaling/scaling.sh"

for file in $SCRIPT_FILES; do
	if [ ! -e "$SCALING_PROJECT_HOME/$file" ]; then
		echo "Required file $SCALING_PROJECT_HOME/$file does not exist."
		exit 1
	fi
done

# check configuration files are placed correctly
CONF_FILES="conf/client.cfg conf/domain.properties conf/experiment.cfg"

for file in $CONF_FILES; do
	if [ ! -e "$SCALING_PROJECT_HOME/$file" ]; then
		echo "Required file $SCALING_PROJECT_HOME/$file does not exist."
		exit 1
	fi
done

# read configuration
source "$SCALING_PROJECT_HOME/conf/client.cfg"
source "$SCALING_PROJECT_HOME/conf/experiment.cfg"

: "${time_add_new_client:?Need to set time_add_new_client non-empty}"
: "${max_clients:?Need to set max_clients non-empty}"
: "${client_wait_time:?Need to set client_wait_time non-empty}"
: "${scaling_type:?Need to set scaling_type non-empty}"
: "${cpu_usage_trigger:?Need to set cpu_usage_trigger non-empty}":

echo "Configuration"
echo "time add new client: $time_add_new_client"
echo "max clients : $max_clients"
echo "client wait time: $client_wait_time"
echo "scaling type: $scaling_type"
echo "cpu_usage_trigger: $cpu_usage_trigger"

# start alarm
"$SCALING_PROJECT_HOME/monitor/alarm.py" $cpu_usage_trigger $scaling_type 2> /dev/null &
echo $! > "$SCALING_PROJECT_HOME/logs/alarm.pid"

# start one monitor for each IP in domain.properties
"$SCALING_PROJECT_HOME/monitor/update_monitor.sh"

# start load generator
main_domain_ip="`cat $SCALING_PROJECT_HOME/conf/domain.properties | grep -v "#" | grep IP | awk 'FNR == 1 {print $2}'`"
"$SCALING_PROJECT_HOME/load_generators/load_generator.sh" $main_domain_ip $time_add_new_client $max_clients $client_wait_time 2> /dev/null &
echo $! > "$SCALING_PROJECT_HOME/logs/load_generator.pid"
