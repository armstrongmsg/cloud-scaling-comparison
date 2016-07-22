#!/bin/bash

IFS=' '
read -r -a ips <<< "`cat $SCALING_PROJECT_HOME/conf/domain.properties | grep -v "#" | grep IP | awk 'BEGIN {ORS=" "} {print $2}'`"

BASE_DOMAIN_IP="${ips[1]}"
MERGED_USAGE_LOG_FILE="$SCALING_PROJECT_HOME/analysis/merged_usage.log"
PLOT_OUTPUT_FILE="$SCALING_PROJECT_HOME/analysis/plots/usage.png"

SCALING_TYPES="CPU_CAP N_CPUs VMs"
for scaling_type in $SCALING_TYPES
do
	USAGE_LOG_FILE="$SCALING_PROJECT_HOME/analysis/$scaling_type/monitor/monitor.$BASE_DOMAIN_IP.log"

	while IFS='' read -r line || [[ -n "$line" ]]; do
		echo "$line $scaling_type" >> $MERGED_USAGE_LOG_FILE
	done < "$USAGE_LOG_FILE"

	sed -i -e 's/,/./g' $MERGED_USAGE_LOG_FILE
done

#Rscript "$SCALING_PROJECT_HOME/analysis/resources_usage.R" "$MERGED_USAGE_LOG_FILE" "$PLOT_OUTPUT_FILE"
