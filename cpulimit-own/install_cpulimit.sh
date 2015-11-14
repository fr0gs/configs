#!/bin/bash
# Automatic installation of cpulimit with own custom parameters.

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
PURPLE='\033[1;35m'
NC='\033[0m' # No Color

if [[ ! -f /usr/bin/cpulimit ]]; then
	echo -e "${PURPLE}[+]:${RED} Installing: ${GREEN} cpulimit ${NC}"	
	sudo apt-get install cpulimit
fi

echo -e "${PURPLE}[+]:${YELLOW} Copying cpulimit_daemon.sh to /usr/bin"
sudo cp cpulimit_scripts/cpulimit_daemon.sh /usr/bin
sudo chmod 700 /usr/bin/cpulimit_daemon.sh

echo -e "${PURPLE}[+]:${YELLOW} Copying cpulimit to /etc/init.d"
sudo cp cpulimit_scripts/cpulimit /etc/init.d/
sudo chown root:root /etc/init.d/cpulimit
sudo chmod +x /etc/init.d/cpulimit
sudo update-rc.d cpulimit defaults

