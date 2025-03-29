fpath+=( $ANTIDOTE_HOME/zsh-users/zsh-history-substring-search )
source $ANTIDOTE_HOME/zsh-users/zsh-history-substring-search/zsh-history-substring-search.plugin.zsh
fpath+=( $ANTIDOTE_HOME/zsh-users/zsh-syntax-highlighting )
source $ANTIDOTE_HOME/zsh-users/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh
if is-macos; then
  fpath+=( $ANTIDOTE_HOME/ohmy/ohmy/plugins/macos )
  source $ANTIDOTE_HOME/ohmy/ohmy/plugins/macos/macos.plugin.zsh
fi
fpath+=( $ANTIDOTE_HOME/zsh-users/zsh-autosuggestions )
source $ANTIDOTE_HOME/zsh-users/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh
fpath+=( $ANTIDOTE_HOME/zdharma-continuum/fast-syntax-highlighting )
source $ANTIDOTE_HOME/zdharma-continuum/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
fpath+=( $ANTIDOTE_HOME/dracula/zsh )
source $ANTIDOTE_HOME/dracula/zsh/dracula.zsh-theme
fpath+=( $ANTIDOTE_HOME/peterhurford/up.zsh )
source $ANTIDOTE_HOME/peterhurford/up.zsh/up.plugin.zsh
fpath+=( $ANTIDOTE_HOME/rummik/zsh-tailf )
source $ANTIDOTE_HOME/rummik/zsh-tailf/tailf.plugin.zsh
fpath+=( $ANTIDOTE_HOME/rupa/z )
source $ANTIDOTE_HOME/rupa/z/z.sh
