#!/usr/bin/fish

###
# This function is a workaround to avoid reading user input
# from stdin and seeing characters being echoed in the screen.
# It tries to emulate the bash "read -s" command.
#
# https://github.com/fish-shell/fish-shell/issues/838
###
function read-password # prompt targetVar
  stty -echo
  head -n 1 | read -g $argv[1]
  stty echo
  echo
end
