# antidote bundle fpath-rule:<rule>

## Setup

```zsh
% source ./tests/__init__.zsh
% t_setup
%
```

By default, fpath is appended to:

```zsh
% antidote bundle foo/bar kind:fpath
fpath+=( "$HOME/.cache/antidote/foo/bar" )
%
```

fpath can be told to explicitly append, but it's unnecessary

```zsh
% antidote bundle foo/bar kind:zsh fpath-rule:append
fpath+=( "$HOME/.cache/antidote/foo/bar" )
source "$HOME/.cache/antidote/foo/bar/bar.plugin.zsh"
%

fpath can be prepended with fpath-rule:prepend

```zsh
% antidote bundle foo/bar kind:fpath fpath-rule:prepend
fpath=( "$HOME/.cache/antidote/foo/bar" $fpath )
%

fpath rules can only be append/prepend

```zsh
% antidote bundle foo/bar kind:fpath fpath-rule:append #=> --exit 0
% antidote bundle foo/bar kind:fpath fpath-rule:prepend #=> --exit 0
% antidote bundle foo/bar kind:fpath fpath-rule:foo 2>&1
antidote: error: unexpected fpath rule: 'foo'
%

fpath rules are also used for `kind:autoload`

```zsh
% antidote bundle foo/baz path:baz kind:autoload fpath-rule:append
fpath+=( "$HOME/.cache/antidote/foo/baz/baz" )
builtin autoload -Uz $fpath[-1]/*(N.:t)
% antidote bundle foo/baz path:baz kind:autoload fpath-rule:prepend
fpath=( "$HOME/.cache/antidote/foo/baz/baz" $fpath )
builtin autoload -Uz $fpath[1]/*(N.:t)
%
```

fpath rules are also used for `autoload:funcdir`

```zsh
% # Append
% antidote bundle foo/baz autoload:baz fpath-rule:append
fpath+=( "$HOME/.cache/antidote/foo/baz/baz" )
builtin autoload -Uz $fpath[-1]/*(N.:t)
fpath+=( "$HOME/.cache/antidote/foo/baz" )
source "$HOME/.cache/antidote/foo/baz/baz.plugin.zsh"
% # Prepend
% antidote bundle foo/baz autoload:baz fpath-rule:prepend
fpath=( "$HOME/.cache/antidote/foo/baz/baz" $fpath )
builtin autoload -Uz $fpath[1]/*(N.:t)
fpath=( "$HOME/.cache/antidote/foo/baz" $fpath )
source "$HOME/.cache/antidote/foo/baz/baz.plugin.zsh"
%
```

fpath rules can be set globally with a zstyle:

`zstyle ':antidote:fpath' rule 'prepend'`

```zsh
% zstyle ':antidote:fpath' rule 'prepend'
% antidote bundle foo/bar
fpath=( "$HOME/.cache/antidote/foo/bar" $fpath )
source "$HOME/.cache/antidote/foo/bar/bar.plugin.zsh"
% antidote bundle foo/bar kind:fpath
fpath=( "$HOME/.cache/antidote/foo/bar" $fpath )
% antidote bundle foo/baz path:baz kind:autoload
fpath=( "$HOME/.cache/antidote/foo/baz/baz" $fpath )
builtin autoload -Uz $fpath[1]/*(N.:t)
%
```

It is NOT recommended to do this, but if you choose to then explicit fpath-rules are
still respected:

```zsh
% zstyle ':antidote:fpath' rule 'prepend'
% antidote bundle foo/bar fpath-rule:append
fpath+=( "$HOME/.cache/antidote/foo/bar" )
source "$HOME/.cache/antidote/foo/bar/bar.plugin.zsh"
% antidote bundle foo/bar kind:fpath fpath-rule:append
fpath+=( "$HOME/.cache/antidote/foo/bar" )
% antidote bundle foo/baz path:baz kind:autoload fpath-rule:append
fpath+=( "$HOME/.cache/antidote/foo/baz/baz" )
builtin autoload -Uz $fpath[-1]/*(N.:t)
%
```

## Teardown

```zsh
% t_teardown
%
```
