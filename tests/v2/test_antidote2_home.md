# antidote2 home tests

## Setup

```zsh
% path+=($PWD)
% subenv() { : "${1:=HOME}"; sed "s|$(eval echo \"\$$1\")|$\\$1|g" ;}
%
```

## General

`antidote2 home` command exists

```zsh
% antidote2 home &>/dev/null; echo $?
0
%
```

`antidote2 home --h/--help` works

```zsh
% antidote2 home -h &>/dev/null; echo $?
0
% antidote2 home --help &>/dev/null; echo $?
0
%
```

`$ANTIDOTE_HOME` is used if set...

```zsh
% export ANTIDOTE_HOME=$HOME/.cache/antidote
% antidote2 home | subenv
$HOME/.cache/antidote
% unset ANTIDOTE_HOME
%
```

`antidote2 home` is `~/Library/Caches/antidote` on macOS

```zsh
% OSTYPE=darwin21.3.0 antidote2 home | subenv
$HOME/Library/Caches/antidote
%
```

`antidote2 home` is `$LOCALAPPDATA/antidote` on msys

```zsh
% OSTYPE=msys LOCALAPPDATA=$HOME/AppData antidote2 home | subenv
$HOME/AppData/antidote
%
```

`antidote2 home` uses `$XDG_CACHE_HOME` on an OS that defines it.

```zsh
% OSTYPE=foobar XDG_CACHE_HOME=$HOME/.xdg-cache antidote2 home | subenv
$HOME/.xdg-cache/antidote
%
```

`antidote2 home` uses `$HOME/.cache` otherwise.

```zsh
% OSTYPE=foobar XDG_CACHE_HOME= antidote2 home | subenv
$HOME/.cache/antidote
%
```

## Teardown

```zsh
% # todo
%
```
