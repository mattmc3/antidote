# shell prereq
if test -z "$ZSH_VERSION"; then
  shellname=$(ps -p $$ -oargs= | awk 'NR=1{print $1}')
  echo >&2 "antidote: Expecting zsh. Found '$shellname'."
  return 1
fi

typeset -f __antidote_setup &>/dev/null && unfunction __antidote_setup
0=${(%):-%N}
autoload -Uz ${0:A:h}/functions/__antidote_setup
__antidote_setup
