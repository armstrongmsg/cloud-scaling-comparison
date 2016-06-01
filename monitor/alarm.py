#!/usr/bin/python

import subprocess
import time
import sys
import os

class Domain_Info:
	def __init__(self, domain_name, domain_ip):
		self.domain_name = domain_name
		self.domain_ip = domain_ip	
		self.n_cpus_vm = 1
		self.cpu_quota = 100000
		self.cpu_period = 100000

	def update(self):
		self.n_cpus_vm = int(subprocess.check_output("virsh dominfo " + self.domain_name + " | grep \"CPU(s)\" | awk '{print$2}'", shell=True))
		self.cpu_quota = int(subprocess.check_output("virsh schedinfo " + self.domain_name + " | grep vcpu_quota | awk '{print $3}'", shell=True))
		self.cpu_period = int(subprocess.check_output("virsh schedinfo " + self.domain_name + " | grep vcpu_period | awk '{print $3}'", shell=True))	


class Environment_Info:
	def __init__(self, domain_names, domain_ips, cpu_usage_file, project_home):		
		# FIXME domain_names length must be > 0
		self.domain_names = domain_names
		self.domain_ips = domain_ips
		self.domain_infos = {self.domain_names[i]:Domain_Info(self.domain_names[i], self.domain_ips[i]) for i in xrange(0, len(self.domain_names))}
		self.cpu_usage_file = cpu_usage_file
		self.project_home = project_home
		self.update()

	def update(self):
		self.n_cpus = int(subprocess.check_output("virsh nodeinfo | grep \"CPU(s)\" | awk '{print $2}'", shell=True))
		for domain_info in self.domain_infos.values():
			domain_info.update()

	def get_vm_cpu_usage(self):
		cpu_usage = 0

		if cpu_usage_collect_method == "virt-top":		
			# FIXME explain the dependance to virt-top output
			cpu_usage=subprocess.check_output("tail -n 1 " + self.cpu_usage_file + " | awk '{print $7}' | awk '{split($0,a,\",\"); print a[1]\".\"a[2]}'", shell=True, cwd=project_home)
			if cpu_usage.strip()[-1] == ".":
				cpu_usage = cpu_usage.strip()[:-1]
			cpu_usage = float(cpu_usage.replace(",", "."))
		else:
			idle = subprocess.check_output("ssh " + user + "@" + self.domain_ips[0] + " sar 1 1 | awk 'FNR == 4 {print $8}'", shell=True, cwd=project_home)
			idle = float(idle.replace(",", "."))
			cpu_usage = 100 - idle
		return cpu_usage

	def get_cpu_usage_trigger(self, proportional_cpu_usage_trigger):
		if cpu_usage_collect_method == "virt-top":
			n_cpus_vm = self.domain_infos[self.domain_names[0]].n_cpus_vm
			cpu_quota = self.domain_infos[self.domain_names[0]].cpu_quota
			cpu_period = self.domain_infos[self.domain_names[0]].cpu_period
			# TODO explain this expression
			return (proportional_cpu_usage_trigger * n_cpus_vm * cpu_quota) / float(self.n_cpus * cpu_period)
		else:
			return proportional_cpu_usage_trigger


def log(text, file):
	file.write(str(time.time()) + " " + text + "\n")
	file.flush()

def get_project_home_path():
	if os.environ.has_key("SCALING_PROJECT_HOME"):
		return os.environ["SCALING_PROJECT_HOME"]
	else:
		print "Please set environment variable SCALING_PROJECT_HOME."
		sys.exit(1)

project_home = get_project_home_path()
proportional_cpu_usage_trigger = int(sys.argv[1])
scaling_type = sys.argv[2]
cpu_usage_collect_method = sys.argv[3]
cpu_log_filename = ""
user = ""

if cpu_usage_collect_method == "ssh":
	user = sys.argv[4]
else:
	cpu_log_filename = sys.argv[4]

monitor_log_filename = project_home + "/logs/monitor/monitor.log"
monitor_cpu_log = project_home + "/logs/monitor/cpu.log"
log_file = open(monitor_log_filename, "a")
cpu_log = open(monitor_cpu_log, "a")
# TODO These values should be read from a conf file or received as argument
env_info = Environment_Info(["lubuntu1"], ["192.168.122.32"], cpu_log_filename, project_home)

# FIXME should process the signals to terminate (close files, etc)
while True:
	time.sleep(1)

	cpu_usage = env_info.get_vm_cpu_usage()
	cpu_usage_trigger = env_info.get_cpu_usage_trigger(proportional_cpu_usage_trigger)
	# TODO log this
	log("Trigger: " + str(cpu_usage_trigger) + "; Usage: " + str(cpu_usage) + " Cpu_quota: " + str(env_info.domain_infos["lubuntu1"].cpu_quota), log_file)
	log(str(cpu_usage), cpu_log)

	if cpu_usage >= cpu_usage_trigger:
		log("CPU Usage triggered scaling: " + scaling_type, log_file)

		if scaling_type in ["CPU_CAP", "N_CPUs"]:

			log("Starting scaling process", log_file)
			subprocess.check_output("bash scaling/scaling.sh " + scaling_type + " " + env_info.domain_names[0], shell=True, cwd=project_home)

			# FIXME should be a constant
			# FIXME explain this sleep
			log("Waiting for scaling", log_file)	
			time.sleep(5)

			log("Updating environment info after scaling", log_file)
			env_info.update()
			cpu_usage_trigger = env_info.get_cpu_usage_trigger(proportional_cpu_usage_trigger)

			# TODO log this
			log("Scaling trigger after scaling: " + str(cpu_usage_trigger), log_file)

