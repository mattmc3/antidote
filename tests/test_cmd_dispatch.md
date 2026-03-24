# antidote dispatch tests

## Setup

```zsh
% source ./tests/__init__.zsh
% t_setup
%
```

## Test dispatch

Dispatch is core to everything, so we don't need to test much here.

```zsh
% antidote-dispatch --version &>/dev/null  #=> --exit 0
%
```

## Lazy config

Tests for lazy-loading antidote.

- Fix [#54](https://github.com/mattmc3/antidote/issues/54)

```zsh
% # Unload antidote
% echo $+functions[antidote-dispatch]
1
% t_unload_antidote
% echo $+functions[antidote-dispatch]
0
% # Now, lazy load it and make sure it works
% autoload -Uz $T_PRJDIR/antidote
% antidote -v &>/dev/null; echo $?
0
% # Now, tear down again
% echo $+functions[antidote-dispatch]
1
% t_unload_antidote
% echo $+functions[antidote-dispatch]
0
% # Now, lazy load from the functions dir
% autoload -Uz $T_PRJDIR/functions/antidote
% antidote -v &>/dev/null; echo $?
0
% echo $+functions[antidote-dispatch]
1
%
```

## Teardown

```zsh
% t_teardown
%
```
