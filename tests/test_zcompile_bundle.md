# antidote load tests

## Setup

```zsh
% source ./tests/_setup.zsh
% source ./antidote.zsh
%
```

### General

Ensure a compiled file does not exist:

```zsh
% zstyle ':antidote:bundle:*' zcompile 'no'
% ! test -e $ZDOTDIR/custom/lib/lib1.zsh.zwc  #=> --exit 0
% antidote bundle $ZDOTDIR/custom/lib/lib1.zsh | subenv
source $ZDOTDIR/custom/lib/lib1.zsh
% ! test -e $ZDOTDIR/custom/lib/lib1.zsh.zwc  #=> --exit 0
% antidote bundle $ZDOTDIR/custom/plugins/mytheme | subenv
fpath+=( $ZDOTDIR/custom/plugins/mytheme )
source $ZDOTDIR/custom/plugins/mytheme/mytheme.zsh-theme
% ! test -e $ZDOTDIR/custom/plugins/mytheme/mytheme.zsh-theme.zwc  #=> --exit 0
%
```

Ensure a compiled file exists:

```zsh
% zstyle ':antidote:bundle:*' zcompile 'yes'
% ! test -e $ZDOTDIR/custom/lib/lib2.zsh.zwc  #=> --exit 0
% antidote bundle $ZDOTDIR/custom/lib/lib2.zsh | subenv
source $ZDOTDIR/custom/lib/lib2.zsh
% test -e $ZDOTDIR/custom/lib/lib2.zsh.zwc  #=> --exit 0
% # plugin
% antidote bundle $ZDOTDIR/custom/plugins/myplugin | subenv
fpath+=( $ZDOTDIR/custom/plugins/myplugin )
source $ZDOTDIR/custom/plugins/myplugin/myplugin.plugin.zsh
% test -e $ZDOTDIR/custom/plugins/myplugin/myplugin.plugin.zsh.zwc  #=> --exit 0
% # zsh-theme
% antidote bundle $ZDOTDIR/custom/plugins/mytheme | subenv
fpath+=( $ZDOTDIR/custom/plugins/mytheme )
source $ZDOTDIR/custom/plugins/mytheme/mytheme.zsh-theme
% test -e $ZDOTDIR/custom/plugins/mytheme/mytheme.zsh-theme.zwc  #=> --exit 0
%
```

## Teardown

```zsh
% t_teardown
%
```
