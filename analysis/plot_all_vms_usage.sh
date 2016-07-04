#!/bin/bash

IFS=' '
read -r -a ips <<< "`cat $SCALING_PROJECT_HOME/conf/domain.properties | grep -v "#" | grep IP | awk 'BEGIN {ORS=" "} {print $2}'`"

for ip in ${ips[@]}
do
	usage_log_file="$SCALING_PROJECT_HOME/logs/monitor/monitor.$ip.log"
	plot_output_file="$SCALING_PROJECT_HOME/analysis/plots/usage.$ip.png"
	
	Rscript "$SCALING_PROJECT_HOME/analysis/resources_usage.R" "$usage_log_file" "$plot_output_file"
done
