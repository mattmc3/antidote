# antidote test alternative zsh-defer repo

## Setup

```zsh
% source ./tests/_setup.zsh
% source ./antidote.zsh
%
```

## Customize zsh-defer

If the user forks zsh-defer, support setting a zstyle for an alternative repo location.

### General

```zsh
% zstyle ':antidote:bundle' use-friendly-names on
% zstyle ':antidote:defer' bundle 'getantidote/zsh-defer'
% antidote bundle 'zsh-users/zsh-autosuggestions kind:defer' 2>/dev/null | subenv ANTIDOTE_HOME
if ! (( $+functions[zsh-defer] )); then
  fpath+=( $ANTIDOTE_HOME/getantidote/zsh-defer )
  source $ANTIDOTE_HOME/getantidote/zsh-defer/zsh-defer.plugin.zsh
fi
fpath+=( $ANTIDOTE_HOME/zsh-users/zsh-autosuggestions )
zsh-defer source $ANTIDOTE_HOME/zsh-users/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh
%
```

## Teardown

```zsh
% t_teardown
%
```
