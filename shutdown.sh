#!/bin/bash

# check required environment variables
: "${SCALING_PROJECT_HOME:?Need to set SCALING_PROJECT_HOME non-empty}"

load_generator_pid="`cat $SCALING_PROJECT_HOME/logs/load_generator.pid `"
alarm_pid="`cat $SCALING_PROJECT_HOME/logs/alarm.pid`"

echo "Shutting down load generator"
kill $load_generator_pid

echo "Shutting down monitor"
kill $alarm_pid
