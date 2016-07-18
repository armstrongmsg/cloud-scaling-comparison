#!/bin/bash

SCALING_TIMES="$SCALING_PROJECT_HOME/analysis/scaling_times.txt"
SCALING_LOG_CPU_CAP="$SCALING_PROJECT_HOME/analysis/CPU_CAP/scaling/scaling.log"
SCALING_LOG_N_CPUs="$SCALING_PROJECT_HOME/analysis/N_CPUs/scaling/scaling.log"
SCALING_LOG_VMs="$SCALING_PROJECT_HOME/analysis/VMs/scaling/scaling.log"

CPU_CAP_TIMES="`cat $SCALING_LOG_CPU_CAP | grep "start-end-times" | awk 'BEGIN { OFS = "-" } {print $2,$3}'`"
N_CPUs_TIMES="`cat $SCALING_LOG_N_CPUs | grep "start-end-times" | awk 'BEGIN { OFS = "-" } {print $2,$3}'`"
VMs_TIMES="`cat $SCALING_LOG_VMs | grep "start-end-times" | awk 'BEGIN { OFS = "-" } {print $2,$3}'`"

for time in $CPU_CAP_TIMES
do
	echo "$time-CPU_CAP" >> $SCALING_TIMES
done

for time in $N_CPUs_TIMES
do
	echo "$time-N_CPUs" >> $SCALING_TIMES
done

for time in $VMs_TIMES
do
	echo "$time-VMs" >> $SCALING_TIMES
done
