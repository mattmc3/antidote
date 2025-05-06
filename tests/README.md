# antidote tests

Tests are using [clitest](https://github.com/aureliojargas/clitest). `clitest` utilizes markdown files in this folder to house the tests in a literate format.

## Setup

A simple setup consists of:

- Remove existing antidote zstyles
- Don't really git things
- Setup antidote

```zsh
source <(zstyle -L ':antidote:*' | awk '{print "zstyle -d",$2}')
function git { echo "$@" }
ANTIDOTE_HOME=$PWD/tests/zdotdir/antidote_home
source ./antidote.zsh
```

But you probably just want to source setup...

```zsh
% source ./tests/__init__.zsh
% t_setup
%
```

## General

`antidote` with no args displays its help:

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

## Version

The `-v/--version` flag displays the current version:

```zsh
% antidote --version
antidote version 1.9.10 (abcd123)
%
```

## Teardown

```zsh
% t_teardown
%
```
