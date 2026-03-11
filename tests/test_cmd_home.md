# antidote home tests

## Setup

```zsh
% source ./tests/__init__.zsh
% t_setup
%
```

## General

`antidote home` command exists

```zsh
% antidote home &>/dev/null; echo $?
0
%
```

`antidote home --h/--help` works

```zsh
% antidote home -h &>/dev/null; echo $?
0
% antidote home --help &>/dev/null; echo $?
0
%
```

`$ANTIDOTE_HOME` is used if set...

```zsh
% ANTIDOTE_HOME=$HOME/.cache/antidote
% antidote home | subenv HOME
$HOME/.cache/antidote
% unset ANTIDOTE_HOME
%
```

`antidote home` is `~/Library/Caches/antidote` on macOS

```zsh
% zstyle ':antidote:test:env' OSTYPE darwin21.3.0
% antidote home | subenv HOME
$HOME/Library/Caches/antidote
% zstyle -d ':antidote:test:env' OSTYPE
%
```

`antidote home` is `$LOCALAPPDATA/antidote` on msys

```zsh
% zstyle ':antidote:test:env' OSTYPE msys
% zstyle ':antidote:test:env' LOCALAPPDATA $HOME/AppData
% antidote home | subenv HOME
$HOME/AppData/antidote
% zstyle -d ':antidote:test:env' OSTYPE
% zstyle -d ':antidote:test:env' LOCALAPPDATA
%
```

`antidote home` uses `$XDG_CACHE_HOME` on an OS that defines it.

```zsh
% # Setup
% zstyle ':antidote:test:env' OSTYPE foobar
% OLD_XDG_CACHE_HOME=$XDG_CACHE_HOME
% export XDG_CACHE_HOME=$HOME/.xdg-cache
% # Run test
% antidote home | subenv XDG_CACHE_HOME
$XDG_CACHE_HOME/antidote
% # Teardown
% zstyle -d ':antidote:test:env' OSTYPE
% XDG_CACHE_HOME=$OLD_XDG_CACHE_HOME
%
```

`antidote home` uses `$HOME/.cache` otherwise.

```zsh
% # Setup
% zstyle ':antidote:test:env' OSTYPE foobar
% OLD_XDG_CACHE_HOME=$XDG_CACHE_HOME
% export XDG_CACHE_HOME=
% # Run test
% antidote home | subenv HOME
$HOME/.cache/antidote
% # Teardown
% zstyle -d ':antidote:test:env' OSTYPE
% XDG_CACHE_HOME=$OLD_XDG_CACHE_HOME
%
```

## Teardown

```zsh
% t_teardown
%
```
