# antidote v2 tests

## Setup

```zsh
% path+=($PWD/bin)
% path+=($PWD/tests/bin)
% export ANTIDOTE_SCRIPT="$PWD/bin/antidote.sh"
%
```

## antidote --version

Show antidote's version:

```zsh
% antidote.sh --version
antidote version 2.0.0
%
```

## antidote --help

Show antidote's functionality:

```zsh
% antidote.sh --help
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
% [ "$(antidote.sh --help)" = "$(antidote.sh -h)" ] || echo "antidote -h is broken"
% [ "$(antidote.sh --help)" = "$(antidote.sh help)" ] || echo "antidote help is broken"
%
```

## antidote --help

Show antidote's functionality:

```zsh
% antidote.sh init | subenv ANTIDOTE_SCRIPT
#!/usr/bin/env zsh
function antidote {
  case "$1" in
    bundle)
      source <( "$ANTIDOTE_SCRIPT" "$@" ) || "$ANTIDOTE_SCRIPT" "$@"
      ;;
    *)
      "$ANTIDOTE_SCRIPT" "$@"
      ;;
  esac
}
%
```

## Teardown

```zsh
% # TODO
%
```
