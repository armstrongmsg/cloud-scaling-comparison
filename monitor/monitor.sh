#!/bin/bash

CPU_USAGE_TRIGGER=10

while [ "1" = "1" ];
do
	CPU_USAGE=`tail -n 1 log_cpu.txt | awk '{print $7}' | awk '{split($0,a,","); print a[1]}'`
	
	echo $CPU_USAGE	
	if [ $CPU_USAGE -gt $CPU_USAGE_TRIGGER ] 
	then
		echo "scaling"
	fi
	sleep 1
done
