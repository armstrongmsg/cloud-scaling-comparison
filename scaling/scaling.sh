#/bin/bash

SCALING_TYPE="$1"
VM_NAME="$2"

CPU_CAP_SCALING=(["25000"]="50000" ["50000"]="75000" ["75000"]="100000" ["100000"]="100000")
N_CPUs_SCALING=(["1"]="2" ["2"]="3" ["3"]="4" ["4"]="4")

N_CPUs=`virsh dominfo $VM_NAME | grep "CPU(s)" | awk '{print $2}'`
CPU_CAP=`virsh schedinfo $VM_NAME | grep vcpu_quota | awk '{print $3}'`

if [ $SCALING_TYPE = "CPU_CAP" ]; then
	# TODO log this
	echo "Increasing CPU cap"
	echo "From $CPU_CAP to ${CPU_CAP_SCALING[$CPU_CAP]}"
	virsh schedinfo $VM_NAME --set vcpu_quota=${CPU_CAP_SCALING[$CPU_CAP]} 	
elif [ $SCALING_TYPE = "N_CPUs" ]; then
	# TODO log this
	echo "Adding CPUs"
	echo "From $N_CPUs to ${N_CPUs_SCALING[$N_CPUs]}"
	virsh setvcpus $VM_NAME ${N_CPUs_SCALING[$N_CPUs]} --current
else
	echo "Unknown scaling type"
fi

