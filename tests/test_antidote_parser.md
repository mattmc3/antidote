# antidote parser tests

The bundle parser takes the antidote bundle format and returns a series of associative
array from the results of `declare -p bundle`

## Setup

```zsh
% source ./tests/inc/assoc_arr_helpers.zsh
% export ANTIDOTE_GIT_SITE=https://fakegitsite.org
% function parser() {; zsh ./functions/antidote_parser.zsh "$@"; }
%
```

Test empty:

```zsh
% parser
% parser '# This is a full line comment'
%
```

Test the parser output from args:

```zsh
% parser foo/bar | normalize_aarr
typeset -A bundle=( [__line__]=1 [name]=foo/bar )
% parser foo/bar kind:zsh | normalize_aarr
typeset -A bundle=( [__line__]=1 [kind]=zsh [name]=foo/bar )
% parser "foo/bar kind:zsh\nbar/baz kind:fpath" | normalize_aarr
typeset -A bundle=( [__line__]=1 [kind]=zsh [name]=foo/bar )
typeset -A bundle=( [__line__]=2 [kind]=fpath [name]=bar/baz )
%
```

Test assoc array for repo

```zsh
% parser -x 'foo/bar' | print_aarr
$assoc_arr  : bundle
__line__    : 1
__path__    : $ANTIDOTE_HOME/foo/bar
__repo__    : foo/bar
__type__    : repo
__url__     : https://fakegitsite.org/foo/bar
name        : foo/bar
%
```

Test assoc array for repo in compatibility mode

```zsh
% ANTIDOTE_COMPATIBILITY_MODE=true parser -x 'foo/bar' | print_aarr
$assoc_arr  : bundle
__line__    : 1
__path__    : $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-fakegitsite.org-SLASH-foo-SLASH-bar
__repo__    : foo/bar
__type__    : repo
__url__     : https://fakegitsite.org/foo/bar
name        : foo/bar
%
```

Test assoc array for path

```zsh
% parser -x '$ZSH_CUSTOM/foo' | print_aarr
$assoc_arr  : bundle
__line__    : 1
__path__    : $ZSH_CUSTOM/foo
__type__    : path
name        : $ZSH_CUSTOM/foo
%
```

Test assoc array for everything

```zsh
% parser -x 'foo/bar branch:baz kind:zsh path:plugins/baz pre:precmd post:"post cmd"' | print_aarr
$assoc_arr  : bundle
__line__    : 1
__path__    : $ANTIDOTE_HOME/foo/bar
__repo__    : foo/bar
__type__    : repo
__url__     : https://fakegitsite.org/foo/bar
branch      : baz
kind        : zsh
name        : foo/bar
path        : plugins/baz
post        : post cmd
pre         : precmd
%
```

## Test specific keys have known values

Test name:

```zsh
% parser 'foo/bar' | aarr_val name
foo/bar
%
```

Test \_type:

```zsh
% parser -x 'foo/bar' | aarr_val __type__
repo
% parser -x 'https://github.com/foo/bar' | aarr_val __type__
url
% parser -x 'git@bitbucket.org:foo/bar' | aarr_val __type__
url
% parser -x '$foo/bar' | aarr_val __type__
path
% parser -x '$foo/bar/baz.zsh' | aarr_val __type__
path
% parser -x '~foo/bar' | aarr_val __type__
path
% parser -x '~/foo' | aarr_val __type__
path
% parser -x './foo.zsh' | aarr_val __type__
path
% parser -x '../foo.zsh' | aarr_val __type__
path
% parser -x 'foo/bar/' | aarr_val __type__
path
% parser -x 'foo:bar' | aarr_val __type__
?
% parser -x 'bad@gitsite.com/foo/bar' | aarr_val __type__
?
% parser -x 'http:/badsite.com/foo/bar' | aarr_val __type__
?
% parser -x 'https://badsite.com/foo/bar/baz' | aarr_val __type__
?
% parser -x 'https://badsite.com/foo' | aarr_val __type__
?
%
```

Test parser for jibberish

```zsh
% parser -x 'a b c d:e:f' 2>&1
antidote: Unexpected bundle annotation on line 1: 'b'.
% parser -x 'foo bar:baz' | print_aarr
$assoc_arr  : bundle
__line__    : 1
__type__    : ?
bar         : baz
name        : foo
%
```

Test JSONL parser output:

```zsh
% parser -j foo/bar
{"__line__":"1","name":"foo/bar"}
% parser -j "foo/bar\nbar/baz"
{"__line__":"1","name":"foo/bar"}
{"__line__":"2","name":"bar/baz"}
% printf '%s\n' a/b "c/d kind:zsh path:plugins/e" | parser -j
{"__line__":"1","name":"a/b"}
{"__line__":"2","kind":"zsh","name":"c/d","path":"plugins/e"}
% printf '%s\n' a/b "c/d kind:zsh path:plugins/e" | parser -jx
{"__line__":"1","__path__":"$ANTIDOTE_HOME/a/b","__repo__":"a/b","__type__":"repo","__url__":"https://fakegitsite.org/a/b","name":"a/b"}
{"__line__":"2","__path__":"$ANTIDOTE_HOME/c/d","__repo__":"c/d","__type__":"repo","__url__":"https://fakegitsite.org/c/d","kind":"zsh","name":"c/d","path":"plugins/e"}
%
```
