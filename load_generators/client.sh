#!/bin/bash

for i in `seq 1 100`;
do
	curl http://localhost:8080/info.php
done
