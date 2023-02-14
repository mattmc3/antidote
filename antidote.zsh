if test -z "$ZSH_VERSION"; then
  echo >&2 "antidote: Expecting zsh. Found '$(ps -p $$ -oargs=)'."
  return 1
else
  if ! typeset -f antidote-main &>/dev/null; then
    autoload -Uz ${0:A:h}/functions/antidote-main
  fi
  antidote-main setup
fi
