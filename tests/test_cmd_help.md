# antidote help tests

## Setup

```zsh
% source ./tests/_setup.zsh
% source ./antidote.zsh
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
antidote(1) Antidote Manual antidote(1)
%
```

`antidote` man pages are in `$MANPATH`
```zsh
% [[ "$MANPATH" == *"$PWD/man:"* ]] || echo 'MANPATH not set properly'
%
```

## antidote-bundle

```zsh
% antidote help bundle | head -n 1 | sed 's/  */ /g'
antidote-bundle(1) Antidote Manual antidote-bundle(1)
% antidote bundle --help | head -n 1 | sed 's/  */ /g'
antidote-bundle(1) Antidote Manual antidote-bundle(1)
% antidote bundle -h | head -n 1 | sed 's/  */ /g'
antidote-bundle(1) Antidote Manual antidote-bundle(1)
%
```

## antidote-help

```zsh
% antidote help help | head -n 1 | sed 's/  */ /g'
antidote-help(1) Antidote Manual antidote-help(1)
% antidote help --help | head -n 1 | sed 's/  */ /g'
antidote-help(1) Antidote Manual antidote-help(1)
% antidote help -h | head -n 1 | sed 's/  */ /g'
antidote-help(1) Antidote Manual antidote-help(1)
%
```

## antidote-home

```zsh
% antidote help home | head -n 1 | sed 's/  */ /g'
antidote-home(1) Antidote Manual antidote-home(1)
% antidote home --help | head -n 1 | sed 's/  */ /g'
antidote-home(1) Antidote Manual antidote-home(1)
% antidote home -h | head -n 1 | sed 's/  */ /g'
antidote-home(1) Antidote Manual antidote-home(1)
%
```

## antidote-init

```zsh
% antidote help init | head -n 1 | sed 's/  */ /g'
antidote-init(1) Antidote Manual antidote-init(1)
% antidote init --help | head -n 1 | sed 's/  */ /g'
antidote-init(1) Antidote Manual antidote-init(1)
% antidote init -h | head -n 1 | sed 's/  */ /g'
antidote-init(1) Antidote Manual antidote-init(1)
%
```

## antidote-install

```zsh
% antidote help install | head -n 1 | sed 's/  */ /g'
antidote-install(1) Antidote Manual antidote-install(1)
% antidote install --help | head -n 1 | sed 's/  */ /g'
antidote-install(1) Antidote Manual antidote-install(1)
% antidote install -h | head -n 1 | sed 's/  */ /g'
antidote-install(1) Antidote Manual antidote-install(1)
%
```

## antidote-list

```zsh
% antidote help list | head -n 1 | sed 's/  */ /g'
antidote-list(1) Antidote Manual antidote-list(1)
% antidote list --help | head -n 1 | sed 's/  */ /g'
antidote-list(1) Antidote Manual antidote-list(1)
% antidote list -h | head -n 1 | sed 's/  */ /g'
antidote-list(1) Antidote Manual antidote-list(1)
%
```

## antidote-load

```zsh
% antidote help load | head -n 1 | sed 's/  */ /g'
antidote-load(1) Antidote Manual antidote-load(1)
% antidote load --help | head -n 1 | sed 's/  */ /g'
antidote-load(1) Antidote Manual antidote-load(1)
% antidote load -h | head -n 1 | sed 's/  */ /g'
antidote-load(1) Antidote Manual antidote-load(1)
%
```

## antidote-path

```zsh
% antidote help path | head -n 1 | sed 's/  */ /g'
antidote-path(1) Antidote Manual antidote-path(1)
% antidote path --help | head -n 1 | sed 's/  */ /g'
antidote-path(1) Antidote Manual antidote-path(1)
% antidote path -h | head -n 1 | sed 's/  */ /g'
antidote-path(1) Antidote Manual antidote-path(1)
%
```

## antidote-update

```zsh
% antidote help update | head -n 1 | sed 's/  */ /g'
antidote-update(1) Antidote Manual antidote-update(1)
% antidote update --help | head -n 1 | sed 's/  */ /g'
antidote-update(1) Antidote Manual antidote-update(1)
% antidote update -h | head -n 1 | sed 's/  */ /g'
antidote-update(1) Antidote Manual antidote-update(1)
%
```

## antidote-script

```zsh
% antidote help script
No manual entry for antidote-script
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
