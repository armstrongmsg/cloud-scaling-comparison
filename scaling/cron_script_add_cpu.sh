#!/bin/bash
#
#
# Add "* * * * * root /root/cron_script_add_cpu.sh" to /etc/crontab
#
#
(sleep 5 && /root/add_cpu.sh) &
(sleep 10 && /root/add_cpu.sh) &
(sleep 15 && /root/add_cpu.sh) &
(sleep 20 && /root/add_cpu.sh) &
(sleep 25 && /root/add_cpu.sh) &
(sleep 30 && /root/add_cpu.sh) &
(sleep 35 && /root/add_cpu.sh) &
(sleep 40 && /root/add_cpu.sh) &
(sleep 45 && /root/add_cpu.sh) &
(sleep 50 && /root/add_cpu.sh) &
(sleep 55 && /root/add_cpu.sh) &
(sleep 60 && /root/add_cpu.sh) &

