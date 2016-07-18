#!/bin/bash

# TODO a better stream editting?
OUTPUT_FILE="$SCALING_PROJECT_HOME/analysis/requests.txt"

CPU_CAP_REQUESTS="`cat "$SCALING_PROJECT_HOME/analysis/CPU_CAP/clients/"requests.* | sort '-' -k1`"
N_CPUs_REQUESTS="`cat "$SCALING_PROJECT_HOME/analysis/N_CPUs/clients/"requests.* | sort '-' -k1`"
VMs_REQUESTS="`cat "$SCALING_PROJECT_HOME/analysis/VMs/clients/"requests.* | sort '-' -k1`"

for request in $CPU_CAP_REQUESTS
do
	echo "$request-CPU_CAP" >> $OUTPUT_FILE
done

for request in $N_CPUs_REQUESTS
do
	echo "$request-N_CPUs" >> $OUTPUT_FILE
done

for request in $VMs_REQUESTS
do
	echo "$request-VMs" >> $OUTPUT_FILE
done
