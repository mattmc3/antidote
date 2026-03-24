# antidote bundle helper tests

## Setup

```zsh
% TESTDATA=$PWD/tests/testdata
% source ./tests/__init__.zsh
% t_setup
% antidote bundle <$ZDOTDIR/.base_test_fixtures.txt &>/dev/null
%
```

## Awk filter repos

The repo parser pulls a list of all git URLs in a bundle file so that we can clone missing ones in parallel.

```zsh
% cat $TESTDATA/.zsh_plugins_repos.txt | antidote-zsh __private__ bundle_parser | antidote-zsh __private__ bulk_clone
zsh_script --kind clone --branch baz foobar/foobar &
zsh_script --kind clone bar/baz &
zsh_script --kind clone getantidote/zsh-defer &
zsh_script --kind clone git@github.com:user/repo &
zsh_script --kind clone http://github.com/user/repo.git &
zsh_script --kind clone https://github.com/foo/baz &
zsh_script --kind clone https://github.com/foo/qux &
zsh_script --kind clone https://github.com/user/repo &
zsh_script --kind clone user/repo &
wait
%
```

Test empty

```zsh
% cat $TESTDATA/.zsh_plugins_empty.txt | antidote-zsh __private__ bundle_parser | antidote-zsh __private__ bulk_clone
%
```

## Bundle parser

Parse a simple repo:

```zsh
% echo foo/bar | antidote __private__ bundle_scripter
zsh_script foo/bar
%
```

```zsh
% echo 'https://github.com/foo/bar path:lib branch:dev' | antidote __private__ bundle_scripter
zsh_script --branch dev --path lib https://github.com/foo/bar
% echo 'git@github.com:foo/bar.git kind:clone branch:main' | antidote __private__ bundle_scripter
zsh_script --branch main --kind clone git@github.com:foo/bar.git
% echo 'foo/bar kind:fpath abc:xyz' | antidote __private__ bundle_scripter
zsh_script --abc xyz --kind fpath foo/bar
% echo 'foo/bar path:plugins/myplugin kind:path  # trailing comment' | antidote __private__ bundle_scripter
zsh_script --kind path --path plugins/myplugin foo/bar
%
```

```zsh
% print 'foo/bar kind:defer\nbar/baz kind:defer\nbaz/qux kind:defer' | antidote __private__ bundle_scripter
zsh_script --kind defer foo/bar
zsh_script --kind defer --skip-load-defer bar/baz
zsh_script --kind defer --skip-load-defer baz/qux
%
```

Handle funky whitespace

```zsh
% cr=$'\r'; lf=$'\n'; tab=$'\t'
% echo "foo/bar${tab}kind:path${cr}${lf}" | antidote __private__ bundle_scripter
zsh_script --kind path foo/bar
%
```

The bundle parser needs to properly handle quoted annotations.

```zsh
% bundle='foo/bar conditional:"is-macos || is-linux"'
% echo $bundle | antidote __private__ bundle_parser | print_aarr
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar
conditional : is-macos || is-linux
% echo $bundle | antidote __private__ bundle_scripter
zsh_script --conditional "is-macos || is-linux" foo/bar
% antidote bundle $bundle
if is-macos || is-linux; then
  fpath+=( "$HOME/.cache/antidote/fakegitsite.com/foo/bar" )
  source "$HOME/.cache/antidote/fakegitsite.com/foo/bar/bar.plugin.zsh"
fi
%
```

```zsh
% bundle="foo/bar pre:'echo hello \$world' post:\"echo \\\"goodbye \$world\\\"\""
% echo $bundle
foo/bar pre:'echo hello $world' post:"echo \"goodbye $world\""
% echo $bundle | antidote __private__ bundle_parser | print_aarr
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar
post        : echo "goodbye $world"
pre         : echo hello $world
% echo $bundle | antidote __private__ bundle_scripter
zsh_script --post "echo \"goodbye \$world\"" --pre "echo hello \$world" foo/bar
% antidote bundle $bundle
echo hello $world
fpath+=( "$HOME/.cache/antidote/fakegitsite.com/foo/bar" )
source "$HOME/.cache/antidote/fakegitsite.com/foo/bar/bar.plugin.zsh"
echo "goodbye $world"
%
```

The bundle parser turns the bundle DSL into zsh_script statements.

```zsh
% antidote __private__ bundle_scripter < $ZDOTDIR/.zsh_plugins.txt
zsh_script ~/foo/bar
zsh_script --path plugins/myplugin \$ZSH_CUSTOM
zsh_script foo/bar
zsh_script git@fakegitsite.com:foo/qux.git
zsh_script --kind clone getantidote/zsh-defer
zsh_script --kind zsh foo/bar
zsh_script --kind fpath foo/bar
zsh_script --kind path foo/bar
zsh_script --path lib ohmy/ohmy
zsh_script --path plugins/extract ohmy/ohmy
zsh_script --kind defer --path plugins/magic-enter ohmy/ohmy
zsh_script --path custom/themes/pretty.zsh-theme ohmy/ohmy
%
```

## Teardown

```zsh
% t_teardown
%
```
