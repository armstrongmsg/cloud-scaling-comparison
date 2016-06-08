#!/usr/bin/python

import subprocess
import time
import sys
import os
import ConfigParser
import logging

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
		self.config = ConfigParser.ConfigParser()
		self.config.read(project_home + "/conf/domain.properties")
		self.domain_names = self.config.sections()
		self.project_home = project_home
		self.update()

	def update(self):
		self.n_cpus = int(subprocess.check_output("virsh nodeinfo | grep \"CPU(s)\" | awk '{print $2}'", shell=True))

	def get_vm_cpu_usage(self):
		vm_to_check = self.config.sections()[0] 
		ip_to_check = self.config_section_map(self.config, vm_to_check)['ip']
		user = self.config_section_map(self.config, vm_to_check)['user']
		idle = subprocess.check_output("ssh " + user + "@" + ip_to_check + " sar 1 1 | awk 'FNR == 4 {print $8}'", shell=True, cwd=project_home)
		idle = float(idle.replace(",", "."))
		cpu_usage = 100 - idle
		return cpu_usage

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

def configure_logging():
	logging.basicConfig(level=logging.DEBUG)

def get_cpu_logger(log_file_path):
	logger = logging.getLogger("cpu_log")

	handler = logging.StreamHandler()
	handler.setLevel(logging.DEBUG)
	logger.addHandler(handler)

	handler = logging.FileHandler(log_file_path)
	logger.addHandler(handler)
	
	return logger

def get_general_logger(log_file_path):
	logger = logging.getLogger("general_log")

	handler = logging.StreamHandler()
	handler.setLevel(logging.DEBUG)
	logger.addHandler(handler)

	handler = logging.FileHandler(log_file_path)
	logger.addHandler(handler)

	return logger

project_home = get_project_home_path()
proportional_cpu_usage_trigger = int(sys.argv[1])
scaling_type = sys.argv[2]

monitor_log_filename = project_home + "/logs/monitor/monitor.log"
monitor_cpu_log = project_home + "/logs/monitor/cpu.log"

configure_logging()
cpu_log = get_cpu_logger(monitor_cpu_log)
log_file = get_general_logger(monitor_log_filename)

env_info = Environment_Info(project_home)

while True:
	time.sleep(1)

	cpu_usage = env_info.get_vm_cpu_usage()
	# TODO log time
	log_file.info("Trigger: " + str(proportional_cpu_usage_trigger) + "; Usage: " + str(cpu_usage))
	# TODO log time
	cpu_log.info(str(cpu_usage))
	
	if cpu_usage >= proportional_cpu_usage_trigger:
		log_file.info("CPU Usage triggered scaling: " + scaling_type)
	
		if scaling_type in ["CPU_CAP", "N_CPUs"]:
			# TODO log time
			log_file.info("Starting scaling process")
			subprocess.check_output("bash scaling/scaling.sh " + scaling_type + " " + env_info.domain_names[0], shell=True, cwd=project_home)
	
			# FIXME should be a constant
			# FIXME explain this sleep
			# TODO log time
			log_file.info("Waiting for scaling")	
			time.sleep(5)	
			
			# TODO log time
			log_file.info("Updating environment info after scaling")
			env_info.update()
	
