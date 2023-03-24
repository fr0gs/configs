# tabtab source for packages
# uninstall by removing these lines
[ -f ~/.config/tabtab/__tabtab.fish ]; and . ~/.config/tabtab/__tabtab.fish; or true

# Set NVM directory
set -gx NVM_DIR ~/.nvm

# Set GOPATH
set -x GOPATH ~/go # the -x flag exports the variable
set PATH $PATH $GOPATH/bin

# Set PYTHONPATH
set -x PYTHONPATH $PYTHONPATH :./src:/Users/esteban/gits/nexvia/nx/library/nxbuild/src:/Users/esteban/gits/nexvia/nx/internal/parking-watcher/src:/Users/esteban/gits/nexvia/nx/internal/content-data-merger/src:/Users/esteban/gits/nexvia/nx/library/nxpy/src

# Add nxdev/ localsync
set -x PATH $PATH /Users/esteban/gits/nexvia/nx/internal/nxdev/bin