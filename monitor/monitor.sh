#!/bin/bash

N_CPUs_VM=`virsh dominfo lubuntu1 | grep "CPU(s)" | awk '{print $2}'`
N_CPUs=`virsh nodeinfo | grep "CPU(s)" | awk '{print $2}'`
CPU_QUOTA=`virsh schedinfo lubuntu1 | grep vcpu_quota | awk '{print $3}'`
CPU_PERIOD=`virsh schedinfo lubuntu1 | grep vcpu_period | awk '{print $3}'`

PROPORTIONAL_CPU_USAGE_TRIGGER=70

while [ "1" = "1" ];
do
	CPU_USAGE=`tail -n 1 log_cpu.txt | awk '{print $7}' | awk '{split($0,a,","); print a[1]}'`
	
	echo $CPU_USAGE	
	echo "$N_CPUs_VM $N_CPUs $CPU_QUOTA $CPU_PERIOD $CPU_USAGE_TRIGGER $PROPORTIONAL_CPU_USAGE_TRIGGER" | awk '{printf "%.f \n", ($5*$1*$3)/($2*$4)}'
	if [ $CPU_USAGE -gt $CPU_USAGE_TRIGGER ] 
	then
		#100 * proporção cpus * cpucap

	fi
	sleep 1
done
