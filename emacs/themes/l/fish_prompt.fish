# name: L
function _git_branch_name
  echo (command git symbolic-ref HEAD ^/dev/null | sed -e 's|^refs/heads/||')
end

function _is_git_dirty
  echo (command git status -s --ignore-submodules=dirty ^/dev/null)
end

function fish_prompt
  set -l blue (set_color blue --bold)
  set -l green (set_color green)
  set -l normal (set_color normal)
  set -l yellow (set_color yellow --bold)

  set -l arrow "λ"
  set -l bold_arrow $yellow(echo $arrow)
  set -l cwd $blue(prompt_pwd)

  if [ (_git_branch_name) ]
    set git_info $green(_git_branch_name)
    set git_info ":$git_info"

    if [ (_is_git_dirty) ]
      set -l dirty "*"
      set git_info "$git_info$dirty"
    end
  end

  echo -n -s $cwd $git_info $normal ' ' $bold_arrow ' '
end
