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
% __antidote_bulk_clone < $TESTDATA/.zsh_plugins_repos.txt
antidote-script --kind clone --branch baz foobar/foobar &
antidote-script --kind clone bar/baz &
antidote-script --kind clone getantidote/zsh-defer &
antidote-script --kind clone git@github.com:user/repo &
antidote-script --kind clone http://github.com/user/repo.git &
antidote-script --kind clone https://github.com/foo/baz &
antidote-script --kind clone https://github.com/foo/qux &
antidote-script --kind clone https://github.com/user/repo &
antidote-script --kind clone user/repo &
wait
%
```

Test empty

```zsh
% __antidote_bulk_clone < $TESTDATA/.zsh_plugins_empty.txt
%
```

## Awk Filter defers

Test that only the first defer block is kept...

```zsh
% __antidote_filter_defers $PWD/tests/testdata/.zsh_plugins_multi_defer.zsh | subenv ANTIDOTE_HOME
fpath+=( $ANTIDOTE_HOME/zsh-users/zsh-history-substring-search )
source $ANTIDOTE_HOME/zsh-users/zsh-history-substring-search/zsh-history-substring-search.plugin.zsh
if ! (( $+functions[zsh-defer] )); then
  fpath+=( $ANTIDOTE_HOME/getantidote/zsh-defer )
  source $ANTIDOTE_HOME/getantidote/zsh-defer/zsh-defer.plugin.zsh
fi
fpath+=( $ANTIDOTE_HOME/zsh-users/zsh-syntax-highlighting )
zsh-defer source $ANTIDOTE_HOME/zsh-users/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh
if is-macos; then
  fpath+=( $ANTIDOTE_HOME/ohmy/ohmy/plugins/macos )
  source $ANTIDOTE_HOME/ohmy/ohmy/plugins/macos/macos.plugin.zsh
fi
fpath+=( $ANTIDOTE_HOME/zsh-users/zsh-autosuggestions )
zsh-defer source $ANTIDOTE_HOME/zsh-users/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh
fpath+=( $ANTIDOTE_HOME/zdharma-continuum/fast-syntax-highlighting )
zsh-defer source $ANTIDOTE_HOME/zdharma-continuum/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
fpath+=( $ANTIDOTE_HOME/dracula/zsh )
source $ANTIDOTE_HOME/dracula/zsh/dracula.zsh-theme
fpath+=( $ANTIDOTE_HOME/peterhurford/up.zsh )
source $ANTIDOTE_HOME/peterhurford/up.zsh/up.plugin.zsh
fpath+=( $ANTIDOTE_HOME/rummik/zsh-tailf )
source $ANTIDOTE_HOME/rummik/zsh-tailf/tailf.plugin.zsh
fpath+=( $ANTIDOTE_HOME/rupa/z )
source $ANTIDOTE_HOME/rupa/z/z.sh
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
antidote-script --path plugins/myplugin \$ZSH_CUSTOM
antidote-script foo/bar
antidote-script git@github.com:foo/qux.git
antidote-script --kind clone getantidote/zsh-defer
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
