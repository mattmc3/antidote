# antidote test alternative zsh-defer repo

## Setup

```zsh
% source ./tests/__init__.zsh
% t_setup
%
```

## Customize zsh-defer

If the user forks zsh-defer, support setting a zstyle for an alternative repo location.

### General

```zsh
% zstyle ':antidote:bundle' use-friendly-names on
% zstyle ':antidote:defer' bundle 'custom/zsh-defer'
% antidote bundle 'zsh-users/zsh-autosuggestions kind:defer' 2>/dev/null
if ! (( $+functions[zsh-defer] )); then
  fpath+=( "$HOME/.cache/antidote/custom/zsh-defer" )
  source "$HOME/.cache/antidote/custom/zsh-defer/zsh-defer.plugin.zsh"
fi
fpath+=( "$HOME/.cache/antidote/zsh-users/zsh-autosuggestions" )
zsh-defer source "$HOME/.cache/antidote/zsh-users/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh"
%
```

## Teardown

```zsh
% t_teardown
%
```
