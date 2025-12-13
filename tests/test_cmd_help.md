# antidote help tests

## Setup

```zsh
% source ./tests/__init__.zsh
% t_setup
%
```

## General

`antidote help` command exists

```zsh
% antidote help &>/dev/null; echo $?
0
%
```

`antidote --h/--help` works

```zsh
% antidote -h &>/dev/null; echo $?
0
% antidote --help &>/dev/null; echo $?
0
%
```

`antidote` man pages work

```zsh
% PAGER=cat man antidote | head -n 1 | sed 's/  */ /g'
ANTIDOTE(1) Antidote Manual ANTIDOTE(1)
%
```

`antidote` man pages are in `$MANPATH`
```zsh
% [[ "$MANPATH" == *"$T_PRJDIR/man:"* ]] || echo "MANPATH not set properly"
%
```

## antidote-bundle

```zsh
% antidote help bundle | head -n 1 | sed 's/  */ /g'
ANTIDOTE-BUNDLE(1) Antidote Manual ANTIDOTE-BUNDLE(1)
% antidote bundle --help | head -n 1 | sed 's/  */ /g'
ANTIDOTE-BUNDLE(1) Antidote Manual ANTIDOTE-BUNDLE(1)
% antidote bundle -h | head -n 1 | sed 's/  */ /g'
ANTIDOTE-BUNDLE(1) Antidote Manual ANTIDOTE-BUNDLE(1)
%
```

## antidote-help

```zsh
% antidote help help | head -n 1 | sed 's/  */ /g'
ANTIDOTE-HELP(1) Antidote Manual ANTIDOTE-HELP(1)
% antidote help --help | head -n 1 | sed 's/  */ /g'
ANTIDOTE-HELP(1) Antidote Manual ANTIDOTE-HELP(1)
% antidote help -h | head -n 1 | sed 's/  */ /g'
ANTIDOTE-HELP(1) Antidote Manual ANTIDOTE-HELP(1)
%
```

## antidote-home

```zsh
% antidote help home | head -n 1 | sed 's/  */ /g'
ANTIDOTE-HOME(1) Antidote Manual ANTIDOTE-HOME(1)
% antidote home --help | head -n 1 | sed 's/  */ /g'
ANTIDOTE-HOME(1) Antidote Manual ANTIDOTE-HOME(1)
% antidote home -h | head -n 1 | sed 's/  */ /g'
ANTIDOTE-HOME(1) Antidote Manual ANTIDOTE-HOME(1)
%
```

## antidote-init

```zsh
% antidote help init | head -n 1 | sed 's/  */ /g'
ANTIDOTE-INIT(1) Antidote Manual ANTIDOTE-INIT(1)
% antidote init --help | head -n 1 | sed 's/  */ /g'
ANTIDOTE-INIT(1) Antidote Manual ANTIDOTE-INIT(1)
% antidote init -h | head -n 1 | sed 's/  */ /g'
ANTIDOTE-INIT(1) Antidote Manual ANTIDOTE-INIT(1)
%
```

## antidote-install

```zsh
% antidote help install | head -n 1 | sed 's/  */ /g'
ANTIDOTE-INSTALL(1) Antidote Manual ANTIDOTE-INSTALL(1)
% antidote install --help | head -n 1 | sed 's/  */ /g'
ANTIDOTE-INSTALL(1) Antidote Manual ANTIDOTE-INSTALL(1)
% antidote install -h | head -n 1 | sed 's/  */ /g'
ANTIDOTE-INSTALL(1) Antidote Manual ANTIDOTE-INSTALL(1)
%
```

## antidote-list

```zsh
% antidote help list | head -n 1 | sed 's/  */ /g'
ANTIDOTE-LIST(1) Antidote Manual ANTIDOTE-LIST(1)
% antidote list --help | head -n 1 | sed 's/  */ /g'
ANTIDOTE-LIST(1) Antidote Manual ANTIDOTE-LIST(1)
% antidote list -h | head -n 1 | sed 's/  */ /g'
ANTIDOTE-LIST(1) Antidote Manual ANTIDOTE-LIST(1)
%
```

## antidote-load

```zsh
% antidote help load | head -n 1 | sed 's/  */ /g'
ANTIDOTE-LOAD(1) Antidote Manual ANTIDOTE-LOAD(1)
% antidote load --help | head -n 1 | sed 's/  */ /g'
ANTIDOTE-LOAD(1) Antidote Manual ANTIDOTE-LOAD(1)
% antidote load -h | head -n 1 | sed 's/  */ /g'
ANTIDOTE-LOAD(1) Antidote Manual ANTIDOTE-LOAD(1)
%
```

## antidote-path

```zsh
% antidote help path | head -n 1 | sed 's/  */ /g'
ANTIDOTE-PATH(1) Antidote Manual ANTIDOTE-PATH(1)
% antidote path --help | head -n 1 | sed 's/  */ /g'
ANTIDOTE-PATH(1) Antidote Manual ANTIDOTE-PATH(1)
% antidote path -h | head -n 1 | sed 's/  */ /g'
ANTIDOTE-PATH(1) Antidote Manual ANTIDOTE-PATH(1)
%
```

## antidote-update

```zsh
% antidote help update | head -n 1 | sed 's/  */ /g'
ANTIDOTE-UPDATE(1) Antidote Manual ANTIDOTE-UPDATE(1)
% antidote update --help | head -n 1 | sed 's/  */ /g'
ANTIDOTE-UPDATE(1) Antidote Manual ANTIDOTE-UPDATE(1)
% antidote update -h | head -n 1 | sed 's/  */ /g'
ANTIDOTE-UPDATE(1) Antidote Manual ANTIDOTE-UPDATE(1)
%
```

## antidote-foo

```zsh
% antidote help foo
No manual entry for antidote-foo
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

## Teardown

```zsh
% t_teardown
%
```
