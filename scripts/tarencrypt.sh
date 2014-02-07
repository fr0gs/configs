#!/bin/bash

SRC=$1
DST=$2

if [ $# -ne 2 ]; then
	echo "$0 <source folder> <destiny folder>"
	exit -1
fi

if [ -f "/usr/bin/openssl" ]; then
	tar -cf - $SRC | openssl aes-128-cbc -salt -out $DST".tar.aes"
else
	echo "install goddamn openssl"
fi
