# antidote test paths with spaces

## Setup

```zsh
% source ./tests/__init__.zsh
% t_setup
% ANTIDOTE_HOME="$HOME/.cache/antidote with spaces"
% mkdir -p -- "$ANTIDOTE_HOME"
%
```

The bundle parser needs to properly handle quoted annotations.

```zsh
% echo 'foo/bar path:"plugins/foo bar/baz"' | antidote __private__ bundle_parser | print_aarr
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar
path        : plugins/foo bar/baz
% echo 'foo/bar' | antidote __private__ bundle_scripter
zsh_script foo/bar
% antidote bundle 'foo/bar'
# antidote cloning foo/bar...
fpath+=( "$HOME/.cache/antidote with spaces/fakegitsite.com/foo/bar" )
source "$HOME/.cache/antidote with spaces/fakegitsite.com/foo/bar/bar.plugin.zsh"
%
```

## Teardown

```zsh
% t_teardown
%
```
