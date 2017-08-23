# Path to Oh My Fish install.
set -q XDG_DATA_HOME
  and set -gx OMF_PATH "$XDG_DATA_HOME/omf"
  or set -gx OMF_PATH "$HOME/.local/share/omf"

set -gx PATH $PATH "$HOME/.rbenv/bin"
set -gx PATH $PATH "$HOME/.rbenv/plugins/ruby-build/bin"

# Load rbenv automatically by appending
# the following to ~/.config/fish/config.fish:

#status --is-interactive; and source (rbenv init -|psub)

# For the colorscheme of omf (bobthefish)
#https://github.com/oh-my-fish/theme-bobthefish
set -g theme_powerline_fonts no
set -g theme_color_scheme zenburn
set -g theme_display_date no


# Load Oh My Fish configuration.
source $OMF_PATH/init.fish
