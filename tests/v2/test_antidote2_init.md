# antidote2 home tests

## Setup

```zsh
% path+=($PWD)
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
      source <( "$PWD/antidote2" bundle "$@" ) || "$PWD/antidote2" bundle "$@"
      ;;
    *)
      "$PWD/antidote2" "$@"
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
