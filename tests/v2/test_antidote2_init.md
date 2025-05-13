# antidote2 home tests

## Setup

```zsh
% path+=($PWD)
% ANTIDOTE_DEBUG=true
% subenv() { : "${1:=HOME}"; sed "s|$(eval echo \"\$$1\")|$\\$1|g" ;}
%
```

## General

`antidote2 init` command exists

```zsh
% antidote2 init &>/dev/null; echo $?
0
%
```

```zsh
% antidote2 init | subenv PWD
#!/usr/bin/env zsh
antidote2() {
  case "$1" in
    bundle)
      source <( "$PWD/functions/antidote2.zsh" bundle "$@" ) || "$PWD/functions/antidote2.zsh" bundle "$@"
      ;;
    *)
      "$PWD/functions/antidote2.zsh" "$@"
      ;;
  esac
}
_antidote2() {
  IFS=' ' read -A reply <<< "help bundle update home purge list init"
}
compctl -K _antidote2 antidote2
%
```

## Teardown

```zsh
% # todo
%
```
