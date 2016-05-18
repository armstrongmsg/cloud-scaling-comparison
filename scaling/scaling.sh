#/bin/bash

SCALING_TYPE="$1"
VM_NAME="$2"
VM_IP="$3"

CPU_CAP_SCALING=(["25000"]="50000" ["50000"]="75000" ["75000"]="100000" ["100000"]="100000")
N_CPUs_SCALING=(["1"]="2" ["2"]="3" ["3"]="4" ["4"]="4")

N_CPUs=`virsh dominfo lubuntu1 | grep "CPU(s)" | awk '{print $2}'`
CPU_CAP=`virsh schedinfo lubuntu1 | grep vcpu_quota | awk '{print $3}'`

if [ $SCALING_TYPE = "CPU_CAP" ]; then
	echo "Increasing CPU cap"
	echo "From $CPU_CAP to ${CPU_CAP_SCALING[$CPU_CAP]}"
	virsh schedinfo $VM_NAME --set vcpu_quota=${CPU_CAP_SCALING[$CPU_CAP]} 	
elif [ $SCALING_TYPE = "N_CPUs" ]; then
	echo "Adding CPUs"
	echo "From $N_CPUs to ${N_CPUs_SCALING[$N_CPUs]}"
	virsh setvcpus $VM_NAME ${N_CPUs_SCALING[$N_CPUs]}
	
	for cpu in `seq 1 ${N_CPUs_SCALING[$N_CPUs]}`;
	do
		#Not working!
		ssh root@$VM_IP 'bash -s' | echo 1 > /sys/devices/system/cpu/cpu$(($cpu-1))/online
	done
else
	echo "Unknown scaling type"
fi

