function {
  0=${(%):-%x}
  local staticfile=${0:A}
  [[ -e ${staticfile} ]] || return 1
  if [[ ! -s ${staticfile}.zwc || ${staticfile} -nt ${staticfile}.zwc ]]; then
    builtin autoload -Uz zrecompile
    zrecompile -pq ${staticfile}
  fi
}
fpath+=( "$HOME/.cache/antidote/foo/bar" )
source "$HOME/.cache/antidote/foo/bar/bar.plugin.zsh"
fpath+=( "$HOME/.cache/antidote/foo/qux" )
source "$HOME/.cache/antidote/foo/qux/qux.plugin.zsh"
fpath+=( "$HOME/.cache/antidote/foo/bar" )
source "$HOME/.cache/antidote/foo/bar/bar.plugin.zsh"
fpath+=( "$HOME/.cache/antidote/foo/bar" )
export PATH="$HOME/.cache/antidote/foo/bar:$PATH"
fpath+=( "$HOME/.cache/antidote/ohmy/ohmy/lib" )
source "$HOME/.cache/antidote/ohmy/ohmy/lib/lib1.zsh"
source "$HOME/.cache/antidote/ohmy/ohmy/lib/lib2.zsh"
source "$HOME/.cache/antidote/ohmy/ohmy/lib/lib3.zsh"
fpath+=( "$HOME/.cache/antidote/ohmy/ohmy/plugins/extract" )
source "$HOME/.cache/antidote/ohmy/ohmy/plugins/extract/extract.plugin.zsh"
fpath=( "$HOME/.cache/antidote/ohmy/ohmy/plugins/docker" $fpath )
source "$HOME/.cache/antidote/ohmy/ohmy/plugins/docker/docker.plugin.zsh"
fpath+=( "$HOME/.cache/antidote/ohmy/ohmy/plugins/docker" )
source "$HOME/.cache/antidote/ohmy/ohmy/plugins/docker/docker.plugin.zsh"
if ! (( $+functions[zsh-defer] )); then
  fpath+=( "$HOME/.cache/antidote/getantidote/zsh-defer" )
  source "$HOME/.cache/antidote/getantidote/zsh-defer/zsh-defer.plugin.zsh"
fi
fpath+=( "$HOME/.cache/antidote/ohmy/ohmy/plugins/magic-enter" )
zsh-defer source "$HOME/.cache/antidote/ohmy/ohmy/plugins/magic-enter/magic-enter.plugin.zsh"
source "$HOME/.cache/antidote/ohmy/ohmy/custom/themes/pretty.zsh-theme"
