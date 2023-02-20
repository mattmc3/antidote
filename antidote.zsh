# shell prereq
if test -z "$ZSH_VERSION"; then
  shellname=$(ps -p $$ -oargs= | awk 'NR=1{print $1}')
  echo >&2 "antidote: Expecting zsh. Found '$shellname'."
  return 1
fi

if ! typeset -f antidote-main &>/dev/null; then
  autoload -Uz ${0:A:h}/functions/antidote-main
fi
antidote-main setup
