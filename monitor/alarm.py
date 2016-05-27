#!/usr/bin/python

import subprocess
import time

class Environment_Info:
	def __init__(self):		
		self.update()

	def update(self):
		# FIXME domain-name dependant
		self.N_CPUs_VM = int(subprocess.check_output("virsh dominfo lubuntu1 | grep \"CPU(s)\" | awk '{print$2}'", shell=True))
		self.N_CPUs = int(subprocess.check_output("virsh nodeinfo | grep \"CPU(s)\" | awk '{print $2}'", shell=True))
		self.CPU_QUOTA = int(subprocess.check_output("virsh schedinfo lubuntu1 | grep vcpu_quota | awk '{print $3}'", shell=True))
		self.CPU_PERIOD = int(subprocess.check_output("virsh schedinfo lubuntu1 | grep vcpu_period | awk '{print $3}'", shell=True))	

	def get_vm_cpu_usage(self):
		# FIXME output file name dependant
		# FIXME explain the dependance to virt-top output
		CPU_USAGE=subprocess.check_output("tail -n 1 monitor/log_cpu.txt | awk '{print $7}' | awk '{split($0,a,\",\"); print a[1]\".\"a[2]}'", shell=True, cwd=WORKING_DIRECTORY)
		if CPU_USAGE.strip()[-1] == ".":
			CPU_USAGE = CPU_USAGE.strip()[:-1]
		CPU_USAGE = float(CPU_USAGE.replace(",", "."))
		return CPU_USAGE

env_info = Environment_Info()

# FIXME should be an argument
PROPORTIONAL_CPU_USAGE_TRIGGER = 70
# FIXME working directory dependant
WORKING_DIRECTORY="/home/armstrongmsg/Workspace/cloud-vertical-scaling"
CPU_USAGE_TRIGGER = (PROPORTIONAL_CPU_USAGE_TRIGGER * env_info.N_CPUs_VM * env_info.CPU_QUOTA) / float(env_info.N_CPUs * env_info.CPU_PERIOD)

print "trigger:", CPU_USAGE_TRIGGER
# FIXME should process the signals to terminate
while True:
	# TODO should sleep here

	# TODO log this
	CPU_USAGE=env_info.get_vm_cpu_usage()

	# TODO log this
	print "trigger:", CPU_USAGE_TRIGGER, "usage:", CPU_USAGE, "ncpus:", env_info.N_CPUs_VM, "quota:", env_info.CPU_QUOTA
	if CPU_USAGE >= CPU_USAGE_TRIGGER:
		print "scaling"
		# FIXME domain-name dependant
		# FIXME scale type dependant
		subprocess.check_output("bash scaling/scaling.sh N_CPUs lubuntu1", shell=True, cwd=WORKING_DIRECTORY)
		# FIXME should be a constant
		# FIXME explain this sleep	
		time.sleep(5)
		env_info.update()
		# TODO explain this expression
		CPU_USAGE_TRIGGER = (PROPORTIONAL_CPU_USAGE_TRIGGER * env_info.N_CPUs_VM * env_info.CPU_QUOTA) / float(env_info.N_CPUs * env_info.CPU_PERIOD)
		# TODO log this
		print "trigger:", CPU_USAGE_TRIGGER

