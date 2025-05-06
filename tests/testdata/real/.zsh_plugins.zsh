fpath+=( "$ZSH_CUSTOM/plugins/myplugin" )
source "$ZSH_CUSTOM/plugins/myplugin/myplugin.plugin.zsh"
fpath+=( "$ANTIDOTE_HOME/zsh-users/zsh-history-substring-search" )
source "$ANTIDOTE_HOME/zsh-users/zsh-history-substring-search/zsh-history-substring-search.plugin.zsh"
fpath+=( "$ANTIDOTE_HOME/zsh-users/zsh-autosuggestions" )
source "$ANTIDOTE_HOME/zsh-users/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh"
fpath+=( "$ANTIDOTE_HOME/zsh-users/zsh-syntax-highlighting" )
source "$ANTIDOTE_HOME/zsh-users/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh"
fpath+=( "$ANTIDOTE_HOME/sindresorhus/pure" )
export PATH="$ANTIDOTE_HOME/romkatv/zsh-bench:$PATH"
fpath+=( "$ANTIDOTE_HOME/mattmc3/zman/functions" )
builtin autoload -Uz $fpath[-1]/*(N.:t)
fpath=( "$ANTIDOTE_HOME/ohmyzsh/ohmyzsh/plugins/gradle" $fpath )
source "$ANTIDOTE_HOME/ohmyzsh/ohmyzsh/plugins/gradle/gradle.plugin.zsh"
fpath+=( "$ANTIDOTE_HOME/ohmyzsh/ohmyzsh/plugins/docker" )
source "$ANTIDOTE_HOME/ohmyzsh/ohmyzsh/plugins/docker/docker.plugin.zsh"
if is-macos; then
  fpath+=( "$ANTIDOTE_HOME/ohmyzsh/ohmyzsh/plugins/macos" )
  source "$ANTIDOTE_HOME/ohmyzsh/ohmyzsh/plugins/macos/macos.plugin.zsh"
fi
fpath+=( "$ANTIDOTE_HOME/mattmc3/antidote" )
source "$ANTIDOTE_HOME/mattmc3/antidote/pz.plugin.zsh"
source "$ANTIDOTE_HOME/ohmyzsh/ohmyzsh/lib/clipboard.zsh"
fpath+=( "$ANTIDOTE_HOME/ohmyzsh/ohmyzsh/plugins/extract" )
source "$ANTIDOTE_HOME/ohmyzsh/ohmyzsh/plugins/extract/extract.plugin.zsh"
fpath+=( "$ANTIDOTE_HOME/ohmyzsh/ohmyzsh/plugins/magic-enter" )
source "$ANTIDOTE_HOME/ohmyzsh/ohmyzsh/plugins/magic-enter/magic-enter.plugin.zsh"
fpath+=( "$ANTIDOTE_HOME/ohmyzsh/ohmyzsh/plugins/fancy-ctrl-z" )
source "$ANTIDOTE_HOME/ohmyzsh/ohmyzsh/plugins/fancy-ctrl-z/fancy-ctrl-z.plugin.zsh"
if ! (( $+functions[zsh-defer] )); then
  fpath+=( "$ANTIDOTE_HOME/romkatv/zsh-defer" )
  source "$ANTIDOTE_HOME/romkatv/zsh-defer/zsh-defer.plugin.zsh"
fi
fpath+=( "$ANTIDOTE_HOME/zdharma-continuum/fast-syntax-highlighting" )
zsh-defer source "$ANTIDOTE_HOME/zdharma-continuum/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
fpath+=( "$ANTIDOTE_HOME/dracula/zsh" )
source "$ANTIDOTE_HOME/dracula/zsh/dracula.zsh-theme"
fpath+=( "$ANTIDOTE_HOME/peterhurford/up.zsh" )
source "$ANTIDOTE_HOME/peterhurford/up.zsh/up.plugin.zsh"
fpath+=( "$ANTIDOTE_HOME/rummik/zsh-tailf" )
source "$ANTIDOTE_HOME/rummik/zsh-tailf/tailf.plugin.zsh"
fpath+=( "$ANTIDOTE_HOME/rupa/z" )
source "$ANTIDOTE_HOME/rupa/z/z.sh"
