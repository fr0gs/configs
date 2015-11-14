#!/bin/bash
# Script to install vim with my colors in a fresh new installation.
# Must be run from the same folder as the .vim & vimrc_propio files.

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
PURPLE='\033[1;35m'
NC='\033[0m' # No Color

if [[ -f /usr/bin/vim-tiny ]]; then
	echo -e "${PURPLE}[+]:${RED} Remove: ${GREEN} vim.tiny ${NC}"
  sudo apt-get remove vim-tiny
fi

if [[ ! -f /usr/bin/vim ]]; then
	echo -e "${PURPLE}[+]:${RED} Installing: ${GREEN} vim vim-doc ${NC}"
	sudo apt-get install vim vim-doc
fi

# The .vim/colors is necessary to save the 
# colorscheme files
echo -e "${PURPLE}[+]:${YELLOW} Creating ~/.vim/colors ${NC}"
mkdir -p ~/.vim
mkdir -p ~/.vim/colors

echo -e "${PURPLE}[+]:${YELLOW} Copying vimrc_propio to ~/.vimrc ${NC}"
cp vimrc_propio ~/.vimrc
echo -e "${PURPLE}[+]:${YELLOW} Copying colorscheme (.vim) files ${NC}"
cp *.vim ~/.vim/colors


