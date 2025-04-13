# antidote init tests

## Setup

```zsh
% source ./tests/__init__.zsh
% t_setup
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

Load plugins dynamically

```zsh
% source <(antidote init)
% antidote bundle foo/bar
sourcing foo/bar...
% antidote bundle foo/baz autoload:functions
sourcing foo/baz...
% antidote bundle $ZDOTDIR/custom/lib
sourcing custom lib1.zsh...
sourcing custom lib2.zsh...
% echo $#plugins
2
% echo $#libs
2
% echo $+functions[baz]
1
%
```

## Teardown

```zsh
% t_teardown
%
```
