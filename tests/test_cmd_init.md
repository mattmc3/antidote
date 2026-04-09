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
      source <( ANTIDOTE_DYNAMIC=true antidote-dispatch $@ ) || ANTIDOTE_DYNAMIC=true antidote-dispatch $@
      ;;
    *)
      ANTIDOTE_DYNAMIC=true antidote-dispatch $@
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

## Dynamic using: directive

using: context persists across calls in dynamic mode

```zsh
% source <(antidote init)
% antidote bundle using:ohmy/ohmy path:plugins
# antidote cloning ohmy/ohmy...
% antidote bundle docker
sourcing plugins/docker/docker.plugin.zsh from ohmy/ohmy...
% antidote bundle extract
sourcing plugins/extract/extract.plugin.zsh from ohmy/ohmy...
% antidote bundle git
sourcing plugins/git/git.plugin.zsh from ohmy/ohmy...
%
```

using: context resets when a new using: is seen

```zsh
% antidote bundle using:foo/bar
% antidote bundle bar.plugin.zsh
sourcing bar.plugin.zsh from foo/bar...
%
```

path-based using: in dynamic mode

```zsh
% antidote bundle using:$ZDOTDIR/custom path:plugins
% antidote bundle myplugin
sourcing myplugin...
% antidote bundle doesnotexist 2>/dev/null
%
```

## Teardown

```zsh
% t_teardown
%
```
