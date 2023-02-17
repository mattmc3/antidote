# antidote bundle helper tests

## Setup

```zsh
% AWKDIR=$PWD/functions/scripts
% TESTDATA=$PWD/tests/testdata
% source ./tests/_setup.zsh
%
```

## Awk parsers

### Get bundle repos

The repo parser pulls a list of all git URLs in a bundle file so that we can clone missing ones in parallel.

```zsh
% awk -f $AWKDIR/get-bundle-repos.awk $TESTDATA/.zsh_plugins_repos.txt | sort | uniq
git@github.com:user/repo
http://github.com/user/repo.git
https://github.com/bar/baz
https://github.com/baz/qux
https://github.com/foobar/foobar --branch baz
https://github.com/qux/baz
https://github.com/romkatv/zsh-defer
https://github.com/user/repo
%
```

Test empty

```zsh
% awk -f $AWKDIR/get-bundle-repos.awk $TESTDATA/.zsh_plugins_empty.txt
%
```

### Filter dupe defers

Test that only the first defer block is kept...

```zsh
% awk -f $AWKDIR/filter-extra-defers.awk $PWD/tests/testdata/.zsh_plugins_multi_defer.zsh | subenv ANTIDOTE_HOME
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-history-substring-search )
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-history-substring-search/zsh-history-substring-search.plugin.zsh
if ! (( $+functions[zsh-defer] )); then
  fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-romkatv-SLASH-zsh-defer )
  source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-romkatv-SLASH-zsh-defer/zsh-defer.plugin.zsh
fi
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-syntax-highlighting )
zsh-defer source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh
if is-macos; then
  fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmy-SLASH-ohmy/plugins/macos )
  source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmy-SLASH-ohmy/plugins/macos/macos.plugin.zsh
fi
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-autosuggestions )
zsh-defer source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-autosuggestions/zsh-autosuggestions.plugin.zsh
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
%
```

Test that with no defers, nothing is altered...

```zsh
% awk -f $AWKDIR/filter-extra-defers.awk $PWD/tests/testdata/.zsh_plugins_no_defer.zsh  #=> --file testdata/.zsh_plugins_no_defer.zsh
%
```

## Teardown

```zsh
% t_teardown
%
```
