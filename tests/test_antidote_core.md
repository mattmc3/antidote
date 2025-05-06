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
% antidote
antidote - the cure to slow zsh plugin management

usage: antidote [<flags>] <command> [<args> ...]

flags:
  -h, --help           Show context-sensitive help
  -v, --version        Show application version

commands:
  help      Show documentation
  load      Statically source all bundles from the plugins file
  bundle    Clone bundle(s) and generate the static load script
  install   Clone a new bundle and add it to your plugins file
  update    Update antidote and its cloned bundles
  purge     Remove a cloned bundle
  home      Print where antidote is cloning bundles
  list      List cloned bundles
  path      Print the path of a cloned bundle
  init      Initialize the shell for dynamic bundles
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
% antidote --version
antidote version 1.9.10 (abcd123)
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
