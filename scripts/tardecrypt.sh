#!/bin/bash
# Decrypts a whole folder encrypted with openssl aes-128-cbc

FOLDER=$1

if [ $# -ne 1 ]; then
	echo "$0 <folder to decrypt>"
	exit -1
fi


if [ -f "/usr/bin/openssl" ]; then
	openssl aes-128-cbc -d -salt -in $FOLDER | tar -x -f -
else
	echo "install goddamn openssl"
fi

