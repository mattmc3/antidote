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
