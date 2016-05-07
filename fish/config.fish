# Path to the Android SDK
set -g -x ANDROID_HOME /opt/android-sdk-linux

# Remove fish greeting
set -g fish_greeting ""

# set React editor
set -g -x REACT_EDITOR emacs24

# start tmux on every login in fish shell
#if status --is-interactive
#   if test -z (echo $TMUX)
#      tmux
#    end
#end
  
