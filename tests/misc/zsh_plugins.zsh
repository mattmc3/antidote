if ! (( $+functions[zsh-defer] )); then
  fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-romkatv-SLASH-zsh-defer )
  source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-romkatv-SLASH-zsh-defer/zsh-defer.plugin.zsh
fi
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar )
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar/bar.plugin.zsh
fpath+=( $ANTIDOTE_HOME/git-AT-github.com-COLON-foo-SLASH-qux )
source $ANTIDOTE_HOME/git-AT-github.com-COLON-foo-SLASH-qux/qux.plugin.zsh
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-bar-SLASH-baz )
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-bar-SLASH-baz/baz.plugin.zsh
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-baz-SLASH-myprompt )
export PATH="$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-baz-SLASH-util:$PATH"
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-baz-SLASH-devbranch )
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-baz-SLASH-devbranch/devbranch.plugin.zsh
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-baz-SLASH-ohmy/lib/clipboard.zsh
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-baz-SLASH-ohmy/plugins/extract )
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-baz-SLASH-ohmy/plugins/extract/extract.plugin.zsh
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-baz-SLASH-deferme )
zsh-defer source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-baz-SLASH-deferme/deferme.plugin.zsh
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-baz-SLASH-mytheme )
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-baz-SLASH-mytheme/mytheme.zsh-theme
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-baz-SLASH-name.zsh )
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-baz-SLASH-name.zsh/name.zsh
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-baz-SLASH-zsh-name )
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-baz-SLASH-zsh-name/name.zsh
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-baz-SLASH-shellscript )
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-baz-SLASH-shellscript/shellscript.sh
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-baz-SLASH-malformed )
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-baz-SLASH-malformed/whatever.plugin.zsh
