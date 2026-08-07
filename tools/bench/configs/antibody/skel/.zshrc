path=("$ZDOTDIR/.antibody/bin" $path)

# antibody has no load command of its own: the documented pattern regenerates
# the static file when the plugin list is newer, then sources it.
if [[ ! -f $ZDOTDIR/.zsh_plugins.zsh
   || $ZDOTDIR/.zsh_plugins.txt -nt $ZDOTDIR/.zsh_plugins.zsh ]]; then
  antibody bundle <$ZDOTDIR/.zsh_plugins.txt >$ZDOTDIR/.zsh_plugins.zsh
fi

autoload -Uz compinit && compinit -u -d "$ZDOTDIR/.zcompdump"
source $ZDOTDIR/.zsh_plugins.zsh
