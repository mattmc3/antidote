fpath+=( "$HOME/.cache/antidote/fakegitsite.com/foo/bar" )
source "$HOME/.cache/antidote/fakegitsite.com/foo/bar/bar.plugin.zsh"
fpath+=( "$HOME/.cache/antidote/fakegitsite.com/foo/qux" )
source "$HOME/.cache/antidote/fakegitsite.com/foo/qux/qux.plugin.zsh"
fpath+=( "$HOME/.cache/antidote/fakegitsite.com/foo/bar" )
source "$HOME/.cache/antidote/fakegitsite.com/foo/bar/bar.plugin.zsh"
fpath+=( "$HOME/.cache/antidote/fakegitsite.com/foo/bar" )
export PATH="$HOME/.cache/antidote/fakegitsite.com/foo/bar:$PATH"
fpath+=( "$HOME/.cache/antidote/fakegitsite.com/ohmy/ohmy/lib" )
source "$HOME/.cache/antidote/fakegitsite.com/ohmy/ohmy/lib/lib1.zsh"
source "$HOME/.cache/antidote/fakegitsite.com/ohmy/ohmy/lib/lib2.zsh"
source "$HOME/.cache/antidote/fakegitsite.com/ohmy/ohmy/lib/lib3.zsh"
fpath+=( "$HOME/.cache/antidote/fakegitsite.com/ohmy/ohmy/plugins/extract" )
source "$HOME/.cache/antidote/fakegitsite.com/ohmy/ohmy/plugins/extract/extract.plugin.zsh"
fpath=( "$HOME/.cache/antidote/fakegitsite.com/ohmy/ohmy/plugins/docker" $fpath )
source "$HOME/.cache/antidote/fakegitsite.com/ohmy/ohmy/plugins/docker/docker.plugin.zsh"
fpath+=( "$HOME/.cache/antidote/fakegitsite.com/ohmy/ohmy/plugins/docker" )
source "$HOME/.cache/antidote/fakegitsite.com/ohmy/ohmy/plugins/docker/docker.plugin.zsh"
if ! (( $+functions[zsh-defer] )); then
  fpath+=( "$HOME/.cache/antidote/fakegitsite.com/getantidote/zsh-defer" )
  source "$HOME/.cache/antidote/fakegitsite.com/getantidote/zsh-defer/zsh-defer.plugin.zsh"
fi
fpath+=( "$HOME/.cache/antidote/fakegitsite.com/ohmy/ohmy/plugins/magic-enter" )
zsh-defer source "$HOME/.cache/antidote/fakegitsite.com/ohmy/ohmy/plugins/magic-enter/magic-enter.plugin.zsh"
source "$HOME/.cache/antidote/fakegitsite.com/ohmy/ohmy/custom/themes/pretty.zsh-theme"
