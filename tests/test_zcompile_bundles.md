# antidote load tests

## Setup

```zsh
% source ./tests/_setup.zsh
% source ./antidote.zsh
%
```

### General

Ensure a compiled file exists:

```zsh
% ! test -e $ZDOTDIR/.zplugins_fake_load.zsh.zwc  #=> --exit 0
% zstyle ':antidote:static' compile 'yes'
% antidote load $ZDOTDIR/.zplugins_fake_load >/dev/null
% cat $ZDOTDIR/.zplugins_fake_load.zsh | subenv  #=> --file testdata/.zplugins_fake_load.zsh
% test -e $ZDOTDIR/.zplugins_fake_load.zsh.zwc  #=> --exit 0
% t_reset
%
```

Ensure a compiled file does not exist:

```zsh
% ! test -e $ZDOTDIR/.zplugins_fake_load.zsh.zwc  #=> --exit 0
% zstyle ':antidote:static' compile 'no'
% antidote load $ZDOTDIR/.zplugins_fake_load >/dev/null
% cat $ZDOTDIR/.zplugins_fake_load.zsh | subenv  #=> --file testdata/.zplugins_fake_load.zsh
% ! test -e $ZDOTDIR/.zplugins_fake_load.zsh.zwc  #=> --exit 0
% t_reset
%
```

## Teardown

```zsh
% t_teardown
%
```
