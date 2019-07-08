### Path to Oh My Fish install.
set -q XDG_DATA_HOME
  and set -gx OMF_PATH "$XDG_DATA_HOME/omf"
  or set -gx OMF_PATH "$HOME/.local/share/omf"


### Set NPM_TOKEN in order to access a private repository.
#set -x NPM_TOKEN (cat (echo $HOME)/.npmrc| grep npm.famoco.com/repository/npm-all | egrep -o "authToken=(.+)" | cut -d= -f2)

### Add NPM bin path to PATH in fish (to access global packages)
set PATH ~/.npm/bin $PATH

### Environment variables for rbenv (managing Ruby versions)
#set -gx PATH $PATH "$HOME/.rbenv/bin"
#set -gx PATH $PATH "$HOME/.rbenv/plugins/ruby-build/bin"

# Load rbenv automatically by appending
# the following to ~/.config/fish/config.fish:
#status --is-interactive; and source (rbenv init -|psub)

### Environment variables for pyenv (managing Python versions)
#set -g -x PYENV_ROOT "$HOME/.pyenv"
#set -g -x PATH $PATH "$PYENV_ROOT/bin"

# Load pyenv automatically with fish shell
#status --is-interactive; and source (pyenv init -|psub)
#status --is-interactive; and . (pyenv virtualenv-init -|psub)


# Load Oh My Fish configuration.
source $OMF_PATH/init.fish
