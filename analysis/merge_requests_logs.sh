#!/bin/bash

OUTPUT_FILE="$SCALING_PROJECT_HOME/logs/clients/requests.txt"

cat "$SCALING_PROJECT_HOME/logs/clients/"requests.* | sort -s -t '-' -k1 -o $OUTPUT_FILE
