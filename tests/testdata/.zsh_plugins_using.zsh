fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/bar/baz" )
fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy/plugins/docker" )
source "$ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy/plugins/docker/docker.plugin.zsh"
fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy/plugins/extract" )
source "$ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy/plugins/extract/extract.plugin.zsh"
fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy/plugins/git" )
source "$ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy/plugins/git/git.plugin.zsh"
fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy/plugins/magic-enter" )
source "$ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy/plugins/magic-enter/magic-enter.plugin.zsh"
fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy/plugins/macos" )
source "$ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy/plugins/macos/macos.plugin.zsh"
export PATH="$ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy/themes/pretty.zsh-theme:$PATH"
source "$ANTIDOTE_HOME/fakegitsite.com/foo/bar/bar.plugin.zsh"
fpath+=( "$ZDOTDIR/custom/plugins/myplugin" )
source "$ZDOTDIR/custom/plugins/myplugin/myplugin.plugin.zsh"
fpath+=( "$ZDOTDIR/custom/plugins/grizwold" )
source "$ZDOTDIR/custom/plugins/grizwold/grizwold.plugin.zsh"
