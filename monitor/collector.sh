#!/bin/bash

COLLECT_INTERVAL=$1
OUTPUT_FILE=$2

virt-top -d $COLLECT_INTERVAL --stream > $OUTPUT_FILE
