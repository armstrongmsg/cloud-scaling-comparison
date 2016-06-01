#/bin/bash

PROJECT_HOME=$SCALING_PROJECT_HOME
SCALING_LOG_FILE="$PROJECT_HOME/logs/scaling/scaling.log"
SCALING_TYPE="$1"
VM_NAME="$2"

function log {
	echo $1 >> $SCALING_LOG_FILE
}

CPU_CAP_SCALING=(["25000"]="50000" ["50000"]="75000" ["75000"]="100000" ["100000"]="100000")
N_CPUs_SCALING=(["1"]="2" ["2"]="3" ["3"]="4" ["4"]="4")

log "-------------------------------------------------------------------"
log "System time: `date +%s%N`"
log "Starting Scaling script"
log "Configuration: Scaling type = $SCALING_TYPE - Domain name: $VM_NAME"

N_CPUs=`virsh dominfo $VM_NAME | grep "CPU(s)" | awk '{print $2}'`
CPU_CAP=`virsh schedinfo $VM_NAME | grep vcpu_quota | awk '{print $3}'`

log "VM configuration"
log "Number of CPUs: $N_CPUs"
log "CPU cap: $CPU_CAP"

if [ $SCALING_TYPE = "CPU_CAP" ]; then
	log "Increasing CPU cap"
	log "From $CPU_CAP to ${CPU_CAP_SCALING[$CPU_CAP]}"
	virsh schedinfo $VM_NAME --set vcpu_quota=${CPU_CAP_SCALING[$CPU_CAP]} 	
elif [ $SCALING_TYPE = "N_CPUs" ]; then
	log "Adding CPUs"
	log "From $N_CPUs to ${N_CPUs_SCALING[$N_CPUs]}"
	virsh setvcpus $VM_NAME ${N_CPUs_SCALING[$N_CPUs]} --current
else
	log "Unknown scaling type"
fi

log "Shutting down Scaling script"

