#!/bin/bash

LOG="version_log.txt"

rm -rf "$LOG"
touch "$LOG"

FLAG=-1

while read line; do
    first=$(echo "$line" | awk -F':' '{ print $1 }')
    if [[ "$first" == "\"dependencies\"" ]]; then
	FLAG=1
    fi
    if [[ "$FLAG" == 1 ]]; then
	lastchar="${line: -1}"
	if [[ "$lastchar" == "," ]]; then
	    line=${line::-1} #remove last character if it is a comma
	fi
	mydep=$(echo $line | awk -F':' '{ print $2 }' | tr -d '"') # print version and remove quotes
	mylib=$(echo $line | awk -F':' '{ print $1 }' | tr -d '"')
	firstchar=$(echo $mydep | head -c 1)
	if [ "$firstchar" == "^" ] || [ "$firstchar" == "~" ]; then
	    vernum=$(cat "node_modules/"$mylib"/package.json" | grep version | awk -F':' '{ print $2 }' | tr -d '"')
	    echo "${mylib}: ${vernum}" >> $LOG
	fi
    fi
    if [[ "$first" == "\"devDependencies\"" ]]; then
	FLAG=-1
    fi
done < package.json
  
