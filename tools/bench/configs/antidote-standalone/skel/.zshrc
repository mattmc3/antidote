# A lone antidote.zsh has no antidote-load and no dynamic mode, so this is
# the documented manual pattern: regenerate the static file when the plugin
# list is newer, then source it. Bundling runs in a subshell so the
# generating shell's state never reaches this one.
if [[ ! -f $ZDOTDIR/.zsh_plugins.zsh
   || $ZDOTDIR/.zsh_plugins.txt -nt $ZDOTDIR/.zsh_plugins.zsh ]]; then
  (
    source $ZDOTDIR/antidote.zsh
    antidote bundle <$ZDOTDIR/.zsh_plugins.txt >$ZDOTDIR/.zsh_plugins.zsh
  )
fi

autoload -Uz compinit && compinit -u -d "$ZDOTDIR/.zcompdump"
source $ZDOTDIR/.zsh_plugins.zsh
