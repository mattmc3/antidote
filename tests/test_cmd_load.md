# antidote load tests

## Setup

```zsh
% source ./tests/__init__.zsh
% t_setup
%
```

### General

```zsh
% antidote load $ZDOTDIR/.zplugins_fake_load
sourcing foo/bar...
sourcing foo/qux...
sourcing foo/bar...
sourcing ohmy/lib/lib1.zsh...
sourcing ohmy/lib/lib2.zsh...
sourcing ohmy/lib/lib3.zsh...
sourcing extract.plugin.zsh...
sourcing docker.plugin.zsh...
sourcing docker.plugin.zsh...
sourcing getantidote/zsh-defer...
sourcing magic-enter.plugin.zsh...
sourcing pretty.zsh-theme...
% cat $ZDOTDIR/.zplugins_fake_load.zsh | subenv  #=> --file testdata/.zplugins_fake_load.zsh
% # cleanup
% t_reset
%
```

### zstyles

```zsh
% cp $ZDOTDIR/.zplugins_fake_load $ZDOTDIR/.zplugins.txt
% zstyle ':antidote:bundle' file $ZDOTDIR/.zplugins.txt
% zstyle ':antidote:static' file $ZDOTDIR/.zplugins.txt
% # the static file should be different
% antidote load 2>&1 | subenv ZDOTDIR
antidote: bundle file and static file are the same '$ZDOTDIR/.zplugins.txt'.
% # fixed...
% zstyle ':antidote:static' file $ZDOTDIR/.zplugins.static.zsh
% # the static file should be different
% antidote load
sourcing foo/bar...
sourcing foo/qux...
sourcing foo/bar...
sourcing ohmy/lib/lib1.zsh...
sourcing ohmy/lib/lib2.zsh...
sourcing ohmy/lib/lib3.zsh...
sourcing extract.plugin.zsh...
sourcing docker.plugin.zsh...
sourcing docker.plugin.zsh...
sourcing getantidote/zsh-defer...
sourcing magic-enter.plugin.zsh...
sourcing pretty.zsh-theme...
% cat $ZDOTDIR/.zplugins.static.zsh | subenv  #=> --file testdata/.zplugins_fake_load.zsh
%
```

## Teardown

```zsh
% t_teardown
%
```
