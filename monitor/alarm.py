#!/usr/bin/python

import subprocess
import time
import sys
import os
import ConfigParser
import logging

# TODO move to other file
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
	def __init__(self, project_home):		
		self.project_home = project_home
		self.update()

	def update(self):
		self.n_cpus = int(subprocess.check_output("virsh nodeinfo | grep \"CPU(s)\" | awk '{print $2}'", shell=True))
		self.config = ConfigParser.ConfigParser()
		self.config.read(self.project_home + "/conf/domain.properties")
		self.domain_names = self.config.sections()
		
	def get_load_balancer_IP(self):
		load_balancer = self.config.sections()[0]
		return self.config_section_map(self.config, load_balancer)['ip']

	def get_vm_cpu_usage(self):
		usages = []

		# exclude the load balancer
		for index in xrange(1, len(self.config.sections())):
			vm = self.config.sections()[index]
			user = self.config_section_map(self.config, vm)['user']
			ip = self.config_section_map(self.config, vm)['ip']
			idle = subprocess.check_output("bash monitor/collector.sh " + user + " " + ip, shell=True, cwd=self.project_home)
			idle = float(idle.replace(",", "."))
			cpu_usage = 100 - idle
			usages.append(cpu_usage)
		return sum(usages)/float(len(usages))
		
	def config_section_map(self, config, section):
		config_dict = {}
		options = config.options(section)
		for option in options:
			try:
				config_dict[option] = config.get(section, option)
				if config_dict[option] == -1:
					DebugPrint("skip: %s" % option)
			except:
				print("exception on %s!" % option)
				config_dict[option] = None
		return config_dict

def get_project_home_path():
	if os.environ.has_key("SCALING_PROJECT_HOME"):
		return os.environ["SCALING_PROJECT_HOME"]
	else:
		print "Please set environment variable SCALING_PROJECT_HOME."
		sys.exit(1)

# TODO move to other file
class Log:
	def __init__(self, name, output_file_path):
		self.logger = logging.getLogger(name)

		handler = logging.StreamHandler()
		handler.setLevel(logging.DEBUG)
		self.logger.addHandler(handler)

		handler = logging.FileHandler(output_file_path)
		self.logger.addHandler(handler)

	def log(self, text):
		self.logger.info(str(time.time()) + " " + text)

def configure_logging():
	logging.basicConfig(level=logging.DEBUG)

project_home = get_project_home_path()
monitor_log_filename = project_home + "/logs/monitor/alarm.log"
error_log_filename = project_home + "/logs/monitor/alarm.error"

configure_logging()

log_file = Log("general log", monitor_log_filename)
error_log = Log("error log", error_log_filename)

# Check arguments
if len(sys.argv) != 3:
	error_log.log("Incorrect number of arguments (" + str(len(sys.argv) - 1) +"). Exiting.")
	exit(1)

if sys.argv[1]  == "":
	error_log.log("Proportional CPU usage trigger is empty. Exiting.")
	exit(1)
elif sys.argv[2]  == "":
	error_log.log("Scaling type is empty. Exiting.")
	exit(1)

proportional_cpu_usage_trigger = int(sys.argv[1])
scaling_type = sys.argv[2]

env_info = Environment_Info(project_home)
load_balancer_IP = env_info.get_load_balancer_IP()

while True:
	time.sleep(1)
	log_file.log("Updating environment info")
	env_info.update()

	log_file.log("Getting environment resources usage")
	cpu_usage = env_info.get_vm_cpu_usage()

	# TODO log how many VMs are being monitored
	log_file.log("Trigger: " + str(proportional_cpu_usage_trigger) + "; Usage: " + str(cpu_usage))
	
	if cpu_usage >= proportional_cpu_usage_trigger:
		log_file.log("CPU Usage triggered scaling: " + scaling_type)
		log_file.log("Starting scaling process")
		scaling_process = subprocess.Popen("bash scaling/scaling.sh " + scaling_type + " " + env_info.domain_names[1] + " " + load_balancer_IP, shell=True, cwd=project_home)

		log_file.log("Waiting for scaling")
		while scaling_process.poll() is None:
			time.sleep(0.5)

		# FIXME should be a constant
		# FIXME explain this sleep
		time.sleep(5)	
				
		log_file.log("Updating environment info after scaling")
		env_info.update()
		log_file.log("Updated environment info")

