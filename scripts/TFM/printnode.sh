#!/bin/bash
# This script works after running a script with the DCE framework
# in the NS3 simulator. Once executed the simulation with waf,
# this script takes a folder in the form of <files-X> where X is the
# node number, and displays the information of all commands executed 
# in that node in a pretty fashion.


RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
PURPLE='\033[1;35m'
NC='\033[0m' # No Color
SLASH="/"
AUX=var/log/
LC=${1: -1}

if [ "$#" -ne 1 ]; then
	echo "Usage: $ ./printnode.sh <files-X>"
	exit -1
fi


if [ $LC == $SLASH ];
then
	DIR=$1$AUX
else
	DIR=$1$SLASH$AUX
fi

NODENUM=$(echo $DIR | head -c 7 | tail -c 1)

echo -e "${RED}NODE: ${GREEN}$NODENUM ${NC}"

for file in `ls $DIR`
do
		#Get first char of string
		PL=$(expr substr $file 1 1)
		#Check if it is a number
		case $PL in [0-9]* )
			echo -e " ${YELLOW}$file/${NC}"
			for fich in `ls $DIR$file/`
			do
				case $fich in
					"cmdline")
						echo -n -e "  ${PURPLE}CMDLINE: ${NC}"
						cat $DIR$file$SLASH$fich
						;;
					"status")
						echo -e "  ${PURPLE}STATUS: ${NC}"
						cat $DIR$file$SLASH$fich
						;;
					"stderr")
						if [ -s $DIR$file$SLASH$fich ];
						then
							echo -e "  ${PURPLE}STDERR: ${NC}"
							cat $DIR$file$SLASH$fich
						else
							echo -e "  ${PURPLE}STDERR: ${NC}"
						fi
						;;
					"stdout")
						echo -e "  ${PURPLE}STDOUT: ${NC}"
						cat $DIR$file$SLASH$fich | awk '{print "\t" $0}'
						;;
				esac
			done
			#Prints a line through the whole screen
			#Change the 1;31 for:
			# 31 -> red
			# 32 -> green
			# 34 -> blue
			printf '\e[1;31m%*s\n\e[0m' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
			;;
		esac
done
