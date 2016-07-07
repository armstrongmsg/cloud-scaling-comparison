#!/bin/bash

SCALING_TIMES="$SCALING_PROJECT_HOME/analysis/scaling_times.txt"
cat "$SCALING_PROJECT_HOME/logs/scaling/scaling.log" | grep "System time" | awk '{print $3}' > $SCALING_TIMES
