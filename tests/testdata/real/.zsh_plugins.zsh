fpath+=( $ZSH_CUSTOM/plugins/myplugin )
source $ZSH_CUSTOM/plugins/myplugin/myplugin.plugin.zsh
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-history-substring-search )
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-history-substring-search/zsh-history-substring-search.plugin.zsh
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-autosuggestions )
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-autosuggestions/zsh-autosuggestions.plugin.zsh
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-syntax-highlighting )
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-sindresorhus-SLASH-pure )
export PATH="$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-romkatv-SLASH-zsh-bench:$PATH"
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-mattmc3-SLASH-zman/functions )
builtin autoload -Uz $fpath[-1]/*(N.:t)
fpath=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmyzsh-SLASH-ohmyzsh/plugins/gradle $fpath )
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmyzsh-SLASH-ohmyzsh/plugins/gradle/gradle.plugin.zsh
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmyzsh-SLASH-ohmyzsh/plugins/docker )
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmyzsh-SLASH-ohmyzsh/plugins/docker/docker.plugin.zsh
if is-macos; then
  fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmyzsh-SLASH-ohmyzsh/plugins/macos )
  source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmyzsh-SLASH-ohmyzsh/plugins/macos/macos.plugin.zsh
fi
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-mattmc3-SLASH-antidote )
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-mattmc3-SLASH-antidote/pz.plugin.zsh
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmyzsh-SLASH-ohmyzsh/lib/clipboard.zsh
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmyzsh-SLASH-ohmyzsh/plugins/extract )
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmyzsh-SLASH-ohmyzsh/plugins/extract/extract.plugin.zsh
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmyzsh-SLASH-ohmyzsh/plugins/magic-enter )
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmyzsh-SLASH-ohmyzsh/plugins/magic-enter/magic-enter.plugin.zsh
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmyzsh-SLASH-ohmyzsh/plugins/fancy-ctrl-z )
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmyzsh-SLASH-ohmyzsh/plugins/fancy-ctrl-z/fancy-ctrl-z.plugin.zsh
if ! (( $+functions[zsh-defer] )); then
  fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-romkatv-SLASH-zsh-defer )
  source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-romkatv-SLASH-zsh-defer/zsh-defer.plugin.zsh
fi
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-zdharma-continuum-SLASH-fast-syntax-highlighting )
zsh-defer source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-zdharma-continuum-SLASH-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-dracula-SLASH-zsh )
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-dracula-SLASH-zsh/dracula.zsh-theme
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-peterhurford-SLASH-up.zsh )
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-peterhurford-SLASH-up.zsh/up.plugin.zsh
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-rummik-SLASH-zsh-tailf )
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-rummik-SLASH-zsh-tailf/tailf.plugin.zsh
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-rupa-SLASH-z )
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-rupa-SLASH-z/z.sh
