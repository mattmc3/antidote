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
      source <( antidote-dispatch $@ ) || antidote-dispatch $@
      ;;
    *)
      antidote-dispatch $@
      ;;
  esac
}
%
```

Load plugins dynamically

```zsh
% source <(antidote init)
% antidote bundle foo/bar
# antidote cloning foo/bar...
sourcing bar.plugin.zsh from foo/bar...
% antidote bundle foo/baz autoload:functions
# antidote cloning foo/baz...
sourcing baz.plugin.zsh from foo/baz...
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
