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

Flags:
  -h, --help           Show context-sensitive help
  -v, --version        Show application version

Commands:
  help [<command>]
    Show documentation

  bundle <bundles>...
    Clone bundle(s) and generate the static load script

  update
    Update antidote and its cloned bundles

  home
    Print where antidote is cloning bundles

  purge <bundle>
    Remove a cloned bundle

  list
    List cloned bundles

  path <bundle>
    Print the path of a cloned bundle

  init
    Initialize the shell for dynamic bundles

  load
    Statically source all bundles from the plugins file

  install
    Clone a new bundle and add it to your plugins file
%
```

## Version

The `-v/--version` flag displays the current version:

```zsh
% antidote --version | scrub_ver
antidote version 2.0.0
%
```

## Teardown

```zsh
% t_teardown
%
```
