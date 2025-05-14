# antidote core tests

Tests for antidote's most basic functionality.

fails gracefully when someone tries bash

```zsh
% bash -c "source ./antidote.zsh"
antidote: Expecting zsh. Found 'bash'.
%
```

## Setup

```zsh
% echo $+functions[antidote]
0
% source ./tests/__init__.zsh
% t_setup
% echo $+functions[antidote]
1
% git --version
mockgit version 0.0.0
%
```

## General

No args displays help:

```zsh
% antidote | head -n 1
antidote - the cure to slow zsh plugin management
%
```

No arg exit status is 2:

```zsh
% antidote >/dev/null; err=$?
% echo $err
2
%
```

## Help

`-h` and `--help` work:

```zsh
% antidote -h >/dev/null; err=$?
% echo $err
0
% antidote --help >/dev/null; err=$?
% echo $err
0
%
```

## Version

`-v` and `--version` work:

```zsh
% antidote --version | scrub_ver
antidote version 2.0.0
% antidote -v >/dev/null; echo $?
0
% antidote --version >/dev/null; echo $?
0
%
```

## Unrecognized options

```zsh
% antidote --foo >/dev/null; err=$?   #=> --regex (bad option|command not found)
% echo $err
1
%
```

## Unrecognized commands

```zsh
% antidote foo; err=$?
antidote: command not found 'foo'
% echo $err
1
%
```

## All commands

```zsh
% cmds=( bundle help home init install list load path purge update main null )
% for cmd in $cmds; printf '%s' $+functions[antidote-$cmd]; echo
111111111110
%
```

## Teardown

```zsh
% t_teardown
%
```
