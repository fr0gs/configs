local user="%(!.%{$fg_bold[red]%}.%{$fg_bold[red]%})%n%{$reset_color%}"
local arroba="%{$fg_bold[green]%}@%{$reset_color%}"

local host="%{$fg_bold[yellow]%}${host_repr[$(hostname)]:-$(hostname)}%{$reset_color%}"
local dir="%{$reset_color%}%{$fg_bold[blue]%}[%~]%{$reset_color%}"

PROMPT=$'╭─ ${user}${arroba}${host}  ${dir} \
╰─>%{$fg[blue]%} $%{$fg_bold[blue]%} %{$reset_color%} '

ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg[green]%}["
ZSH_THEME_GIT_PROMPT_SUFFIX="]%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY=" %{$fg[red]%}✗%{$fg[green]%}"
