# antidote init tests

## Setup

```zsh
% TESTDIR=$PWD/tests
% source $TESTDIR/scripts/setup.zsh
%
```

## Init

```zsh
% antidote init
#!/usr/bin/env zsh
function antidote {
  case "$1" in
    bundle)
      source <( antidote-main $@ ) || antidote-main $@
      ;;
    *)
      antidote-main $@
      ;;
  esac
}
%
```

## Teardown

```zsh
% t_teardown
%
```
