# antidote v2 tests

## setup

```zsh
% source $PWD/tests/t_init.zsh
%
```

## antidote version

```zsh
% antidote2 --version
antidote version 2.0.0 (abcd123)
%
% # Ensure aliases all work
% test "$(antidote2 --version)" = "$(antidote2 -v)" #=> --exit 0
%
```

## antidote help

```zsh
% antidote2 --help
antidote - the cure to slow zsh plugin management

Usage: antidote [<flags>] <command> [<args> ...]

Flags:
  -h, --help           Show context-sensitive help
  -v, --version        Show application version

Commands:
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
% # Ensure aliases all work
% test "$(antidote2 --help)" = "$(antidote2 -h)" #=> --exit 0
% test "$(antidote2 --help)" = "$(antidote2 help)" #=> --exit 0
%
```

## antidote home

`antidote home` command exists

```zsh
% antidote2 home &>/dev/null; echo $?
0
%
```

`antidote home --h/--help` works

```zsh
% antidote2 home --help
usage: antidote home

Prints where antidote is cloning bundles

Flags:
  -h, --help   Show context-sensitive help.
% test "$(antidote2 home --help)" = "$(antidote2 home -h)" #=> --exit 0
% test "$(antidote2 home --help)" = "$(antidote2 help home)" #=> --exit 0
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

`antidote home` is `~/Library/Caches/antidote` on macOS

```zsh
% export ANTIDOTE_OSTYPE=darwin21.3.0
% antidote2 home | subenv
$HOME/Library/Caches/antidote
% unset ANTIDOTE_OSTYPE
%
```

`antidote home` is `$LOCALAPPDATA/antidote` on msys

```zsh
% export ANTIDOTE_OSTYPE=msys
% export LOCALAPPDATA=$HOME/AppData
% antidote2 home | subenv
$HOME/AppData/antidote
% unset ANTIDOTE_OSTYPE LOCALAPPDATA
%
```

`antidote home` uses `$XDG_CACHE_HOME` on an OS that defines it.

```zsh
% # Setup
% export ANTIDOTE_OSTYPE=foobar
% OLD_XDG_CACHE_HOME=$XDG_CACHE_HOME; XDG_CACHE_HOME=$HOME/.xdg-cache
% # Run test
% antidote2 home | subenv XDG_CACHE_HOME
$XDG_CACHE_HOME/antidote
% # Teardown
% unset ANTIDOTE_OSTYPE; XDG_CACHE_HOME=$OLD_XDG_CACHE_HOME
%
```

`antidote home` uses `$HOME/.cache` otherwise.

```zsh
% # Setup
% export ANTIDOTE_OSTYPE=foobar
% OLD_XDG_CACHE_HOME=$XDG_CACHE_HOME; XDG_CACHE_HOME=
% # Run test
% antidote2 home | subenv
$HOME/.cache/antidote
% # Teardown
% unset ANTIDOTE_OSTYPE; XDG_CACHE_HOME=$OLD_XDG_CACHE_HOME
%
```

## antidote init

```zsh
% antidote2 init | subenv
#!/usr/bin/env zsh
antidote() {
  local antidote_cmd="$PWD/antidote2"
  case "$1" in
    bundle)
      source <( $antidote_cmd $@ ) || $antidote_cmd $@
      ;;
    *)
      $antidote_cmd $@
      ;;
  esac
}

_antidote() {
  IFS=' ' read -A reply <<< "help bundle update home purge list init"
}
compctl -K _antidote antidote
%
```

## private functions

Test cache_dir

```zsh
% export ANTIDOTE_OSTYPE=foobar
% OLD_XDG_CACHE_HOME=$XDG_CACHE_HOME; export XDG_CACHE_HOME=$HOME/.xdg-cache
% antidote2 --debug run cache_dir | subenv
$HOME/.xdg-cache
% unset ANTIDOTE_OSTYPE; XDG_CACHE_HOME=$OLD_XDG_CACHE_HOME
%
```
