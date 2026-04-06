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
% cat $TESTDATA/.zsh_plugins_repos.txt | antidote-zsh __private__ bulk_clone
zsh_script __bundle__ bar/baz kind clone &
zsh_script __bundle__ foobar/foobar kind clone branch baz &
zsh_script __bundle__ getantidote/zsh-defer kind clone &
zsh_script __bundle__ git@github.com:user/repo kind clone &
zsh_script __bundle__ http://github.com/user/repo.git kind clone &
zsh_script __bundle__ https://github.com/foo/baz kind clone &
zsh_script __bundle__ https://github.com/foo/qux kind clone &
zsh_script __bundle__ https://github.com/user/repo kind clone &
zsh_script __bundle__ user/repo kind clone &
wait
%
```

Test empty

```zsh
% cat $TESTDATA/.zsh_plugins_empty.txt | antidote-zsh __private__ bulk_clone
%
```

## Bundle parser

Parse a simple repo:

```zsh
% echo foo/bar | antidote __private__ bundle_scripter
zsh_script __bundle__ foo/bar __type__ repo
%
```

```zsh
% echo 'https://github.com/foo/bar path:lib branch:dev' | antidote __private__ bundle_scripter
zsh_script __bundle__ https://github.com/foo/bar __type__ url branch dev path lib
% echo 'git@github.com:foo/bar.git kind:clone branch:main' | antidote __private__ bundle_scripter
zsh_script __bundle__ git@github.com:foo/bar.git __type__ ssh_url branch main kind clone
% echo 'foo/bar kind:fpath abc:xyz' | antidote __private__ bundle_scripter
zsh_script __bundle__ foo/bar __type__ repo abc xyz kind fpath
% echo 'foo/bar path:plugins/myplugin kind:path  # trailing comment' | antidote __private__ bundle_scripter
zsh_script __bundle__ foo/bar __type__ repo kind path path plugins/myplugin
%
```

```zsh
% print 'foo/bar kind:defer\nbar/baz kind:defer\nbaz/qux kind:defer' | antidote __private__ bundle_scripter
zsh_script __bundle__ foo/bar __type__ repo kind defer
zsh_script __bundle__ bar/baz __type__ repo kind defer __skip_load_defer__ 1
zsh_script __bundle__ baz/qux __type__ repo kind defer __skip_load_defer__ 1
%
```

Handle funky whitespace

```zsh
% cr=$'\r'; lf=$'\n'; tab=$'\t'
% echo "foo/bar${tab}kind:path${cr}${lf}" | antidote __private__ bundle_scripter
zsh_script __bundle__ foo/bar __type__ repo kind path
%
```

The bundle parser needs to properly handle quoted annotations.

```zsh
% bundle='foo/bar conditional:"is-macos || is-linux"'
% echo $bundle | antidote __private__ bundle_parser_serialize | print_parsed_bundle
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar
conditional : is-macos || is-linux
% echo $bundle | antidote __private__ bundle_scripter
zsh_script __bundle__ foo/bar __type__ repo conditional 'is-macos || is-linux'
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
% echo $bundle | antidote __private__ bundle_parser_serialize | print_parsed_bundle
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar
post        : echo "goodbye $world"
pre         : echo hello $world
% echo $bundle | antidote __private__ bundle_scripter
zsh_script __bundle__ foo/bar __type__ repo post 'echo "goodbye $world"' pre 'echo hello $world'
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
zsh_script __bundle__ ~/foo/bar __type__ path
zsh_script __bundle__ '$ZSH_CUSTOM' __type__ empty path plugins/myplugin
zsh_script __bundle__ foo/bar __type__ repo
zsh_script __bundle__ git@fakegitsite.com:foo/qux.git __type__ ssh_url
zsh_script __bundle__ getantidote/zsh-defer __type__ repo kind clone
zsh_script __bundle__ foo/bar __type__ repo kind zsh
zsh_script __bundle__ foo/bar __type__ repo kind fpath
zsh_script __bundle__ foo/bar __type__ repo kind path
zsh_script __bundle__ ohmy/ohmy __type__ repo path lib
zsh_script __bundle__ ohmy/ohmy __type__ repo path plugins/extract
zsh_script __bundle__ ohmy/ohmy __type__ repo kind defer path plugins/magic-enter
zsh_script __bundle__ ohmy/ohmy __type__ repo path custom/themes/pretty.zsh-theme
%
```

## Teardown

```zsh
% t_teardown
%
```
