#/bin/bash

PROJECT_HOME=$SCALING_PROJECT_HOME
SCALING_LOG_FILE="$PROJECT_HOME/logs/scaling/scaling.log"
ERROR_LOG_FILE="$PROJECT_HOME/logs/scaling/scaling.error"
DOMAIN_CONF_FILE="$PROJECT_HOME/conf/domain.properties"
# FIXME conf file?
BASE_DOMAIN="for_cloning"
# FIXME HARDCODED
USER="armstrong"
VMs_IMAGES_DIR="/local/VMs"
SCALING_TYPE="$1"
VM_NAME="$2"
LOAD_BALANCER_IP="$3"

function log {
	echo $1 >> $SCALING_LOG_FILE
}

function log_error {
	echo $1 >> $ERROR_LOG_FILE
}

CPU_CAP_SCALING=(["25000"]="50000" ["50000"]="75000" ["75000"]="100000" ["100000"]="100000")
N_CPUs_SCALING=(["1"]="2" ["2"]="3" ["3"]="4" ["4"]="4")

#Check arguments
if [ $# -ne 3 ]
then
	log_error "Incorrect number of arguments ($#). Exiting."
	exit 1
fi

if [ -z "$SCALING_TYPE" ]
then
	log_error "SCALING_TYPE is empty. Exiting."
	exit 1
elif [ -z "$VM_NAME" ]
then
	log_error "VM_NAME is empty. Exiting."
	exit 1
elif [ -z "$LOAD_BALANCER_IP" ]
then
	log_error "LOAD_BALANCER_IP is empty. Exiting."
	exit 1
fi


START_TIME="`date +%s%N`"
log "-------------------------------------------------------------------"
log "System time: `date +%s%N`"
log "Starting Scaling script"
log "Configuration: Scaling type = $SCALING_TYPE - Domain name: $VM_NAME"

N_CPUs=`virsh dominfo $VM_NAME | grep "CPU(s)" | awk '{print $2}'`
CPU_CAP=`virsh schedinfo $VM_NAME | grep vcpu_quota | awk '{print $3}'`
N_VMs=`cat $DOMAIN_CONF_FILE | grep -v "#" | grep "IP" | wc -l`

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
elif [ $SCALING_TYPE = "VMs" ]; then
	log "Adding VM"
	NEW_VM_NAME="Ubuntu_$(($N_VMs + 1))"

	log "New VM name: $NEW_VM_NAME"
	virt-clone -o $BASE_DOMAIN --name $NEW_VM_NAME --file "$VMs_IMAGES_DIR/$NEW_VM_NAME"
	virsh start $NEW_VM_NAME

	# FIXME this is bad. The script is dependent on the time that the VM uses to startup
	# Maybe a better option cat /var/lib/libvirt/dnsmasq/default.leases | grep $mac | awk '{print $3}'
	sleep 30
	
	VM_MAC="`virsh domiflist $NEW_VM_NAME | awk 'FNR == 3 {print $5}'`"
	VM_IP="`arp -e | grep $VM_MAC | awk '{print $1}'`"

	log "VM IP: $VM_IP"

	# avoid ssh asking for confirmation	
	ssh-keyscan $VM_IP >> ~/.ssh/known_hosts
	
	# add vm to domain.properties
	echo >> $DOMAIN_CONF_FILE

	echo "[$NEW_VM_NAME]" >> $DOMAIN_CONF_FILE
	echo "IP: $VM_IP" >> $DOMAIN_CONF_FILE
	echo "user: $USER" >> $DOMAIN_CONF_FILE 
	
	# add vm to /etc/haproxy/haproxy.cfg
	echo "    server $NEW_VM_NAME $VM_IP:8080 check" | ssh "$USER"@"$LOAD_BALANCER_IP" "cat >> /home/$USER/haproxy.cfg"
	ssh root@$LOAD_BALANCER_IP service haproxy restart
	# TODO haproxy hot config reload
	
	# FIXME should be here?
	"$SCALING_PROJECT_HOME/monitor/update_monitor.sh"
else
	log "Unknown scaling type"
fi

END_TIME="`date +%s%N`"
log "start-end-times: $START_TIME $END_TIME"
log "Shutting down Scaling script"

