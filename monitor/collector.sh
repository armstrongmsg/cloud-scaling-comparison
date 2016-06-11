#!/bin/bash

VM_USER=$1
VM_IP=$2

echo "`ssh $VM_USER@$VM_IP sar 1 1 | awk 'FNR == 4 {print $8}'`"
