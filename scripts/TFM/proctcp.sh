#!/bin/bash
# Script to check all tcp related parameters in /proc/sys/ipv4.
# Useful when you want to have a colorful way to see differences 
# in tcp defaults when you are switching between kernel versions



echo -e "******************************************"
echo -e "TCP PARAMETERS FOUND IN PROC"
echo "kernel version: $(uname -r -s)"
echo -e "******************************************"

for file in `find /proc/sys/net/ipv4 -type f | grep tcp`
do
	if [ -r $file ];
	then
		echo $file | awk -F'/'  '{printf $6 " -> "}'
		cat $file
	fi
done
