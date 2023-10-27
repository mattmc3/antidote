# antidote bundle helper tests

## Setup

```zsh
% TESTDATA=$PWD/tests/testdata
% source ./tests/_setup.zsh
% source ./antidote.zsh
% antidote-bundle -h &>/dev/null
%
```

## Awk filter repos

The repo parser pulls a list of all git URLs in a bundle file so that we can clone missing ones in parallel.

```zsh
% __antidote_bulk_clone $TESTDATA/.zsh_plugins_repos.txt
antidote-script --kind clone --branch baz foobar/foobar &
antidote-script --kind clone bar/baz &
antidote-script --kind clone git@github.com:user/repo &
antidote-script --kind clone http://github.com/user/repo.git &
antidote-script --kind clone https://github.com/baz/qux &
antidote-script --kind clone https://github.com/qux/baz &
antidote-script --kind clone https://github.com/user/repo &
antidote-script --kind clone romkatv/zsh-defer &
antidote-script --kind clone user/repo &
wait
%
```

Test empty

```zsh
% __antidote_bulk_clone $TESTDATA/.zsh_plugins_empty.txt
wait
%
```

## Awk Filter defers

Test that only the first defer block is kept...

```zsh
% __antidote_filter_defers $PWD/tests/testdata/.zsh_plugins_multi_defer.zsh | subenv ANTIDOTE_HOME
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
% __antidote_filter_defers $PWD/tests/testdata/.zsh_plugins_no_defer.zsh  #=> --file testdata/.zsh_plugins_no_defer.zsh
%
```

## Awk Bundle parser

Parse a simple repo:

```zsh
% echo foo/bar | __antidote_parse_bundles
antidote-script foo/bar
%
```

```zsh
% echo 'https://github.com/foo/bar path:lib branch:dev' | __antidote_parse_bundles
antidote-script --path lib --branch dev https://github.com/foo/bar
% echo 'git@github.com:foo/bar.git kind:clone branch:main' | __antidote_parse_bundles
antidote-script --kind clone --branch main git@github.com:foo/bar.git
% echo 'foo/bar kind:fpath abc:xyz' | __antidote_parse_bundles
antidote-script --kind fpath --abc xyz foo/bar
% echo 'foo/bar path:plugins/myplugin kind:path  # trailing comment' | __antidote_parse_bundles
antidote-script --path plugins/myplugin --kind path foo/bar
%
```

Handle funky whitespace

```zsh
% cr=$'\r'; lf=$'\n'; tab=$'\t'
% echo "foo/bar${tab}kind:path${cr}${lf}" | __antidote_parse_bundles
antidote-script --kind path foo/bar
%
```

The bundle parser is an awk script that turns the bundle DSL into antidote-script statements.

```zsh
% __antidote_parse_bundles $ZDOTDIR/.zsh_plugins.txt
antidote-script ~/foo/bar
antidote-script \$ZDOTDIR/foo/bar
antidote-script --path baz \$ZDOTDIR/foo/bar
antidote-script foo/bar
antidote-script git@github.com:baz/qux.git
antidote-script --kind clone romkatv/zsh-defer
antidote-script --kind zsh foo/bar
antidote-script --kind fpath foo/bar
antidote-script --kind path foo/bar
antidote-script --path lib ohmy/ohmy
antidote-script --path plugins/extract ohmy/ohmy
antidote-script --path plugins/magic-enter --kind defer ohmy/ohmy
antidote-script --path custom/themes/pretty.zsh-theme ohmy/ohmy
%
```

## Teardown

```zsh
% t_teardown
%
```
