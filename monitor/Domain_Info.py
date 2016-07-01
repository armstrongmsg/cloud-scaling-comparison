import subprocess

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
