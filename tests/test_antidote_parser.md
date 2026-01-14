# antidote parser tests

## Setup

```zsh
% source ./tests/inc/normalize_aarr.zsh
% export ANTIDOTE_GIT_SITE=https://fakegitsite.org
% function parser() {; zsh ./functions/antidote_parser.zsh "$@"; }
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
