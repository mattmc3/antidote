# antidote load tests

## Setup

```zsh
% source ./tests/__init__.zsh
% t_setup
% antidote bundle <$ZDOTDIR/.base_test_fixtures.txt &>/dev/null
%
```

### General

Ensure a compiled file exists:

```zsh
% zstyle ':antidote:static' zcompile 'yes'
% zstyle ':antidote:static' file $ZDOTDIR/.zplugins_fake_zcompile_static.zsh
% ! test -e $ZDOTDIR/.zplugins_fake_zcompile_static.zsh.zwc  #=> --exit 0
% antidote load $ZDOTDIR/.zplugins_fake_load >/dev/null
% cat $ZDOTDIR/.zplugins_fake_zcompile_static.zsh | subenv  #=> --file testdata/.zplugins_fake_zcompile_static.zsh
% test -e $ZDOTDIR/.zplugins_fake_zcompile_static.zsh.zwc  #=> --exit 0
% t_reset
% antidote bundle <$ZDOTDIR/.base_test_fixtures.txt &>/dev/null
%
```

Bundling a bad repo should produce no output, not even the zcompile header:

```zsh
% zstyle ':antidote:static' zcompile 'yes'
% antidote bundle does-not/exist 2>/dev/null  #=> --exit 1
% zstyle ':antidote:static' zcompile 'no'
%
```

Ensure a compiled file does not exist:

```zsh
% zstyle ':antidote:static' zcompile 'no'
% zstyle ':antidote:static' file $ZDOTDIR/.zplugins_fake_load.zsh
% ! test -e $ZDOTDIR/.zplugins_fake_load.zsh.zwc  #=> --exit 0
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
