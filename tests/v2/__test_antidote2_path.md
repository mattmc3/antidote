# antidote2 path tests

## Setup

```zsh
% path+=($PWD)
% ANTIDOTE_DEBUG=true
% subenv() { : "${1:=HOME}"; sed "s|$(eval echo \"\$$1\")|$\\$1|g" ;}
%
```

## General

`antidote2 path` command exists

```zsh
% antidote2 path &>/dev/null; echo $?
0
%
```

`antidote2 path --h/--help` works

```zsh
% antidote2 path -h &>/dev/null; echo $?
0
% antidote2 path --help &>/dev/null; echo $?
0
%
```

## Path Command

`antidote2 path` prints path to bundle.

```zsh
% antidote2 path foo/bar &>/dev/null  #=> --exit 0
% antidote2 path foo/bar | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/foo/bar
%
```

`antidote2 path` fails on missing bundles

```zsh
% antidote2 path bar/foo &>/dev/null  #=> --exit 1
% antidote2 path bar/foo; echo $?
antidote: error: bar/foo does not exist in cloned paths
1
%
```

`antidote2 path` accepts piped input

```zsh
% antidote2 list -p | antidote2 path | sort | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/foo/bar
$ANTIDOTE_HOME/foo/baz
$ANTIDOTE_HOME/foo/qux
$ANTIDOTE_HOME/getantidote/zsh-defer
$ANTIDOTE_HOME/ohmy/ohmy
%
```

`antidote2 path` handles real paths

```zsh
% ZSH_CUSTOM=${ZDOTDIR:-$HOME}/custom
% antidote2 path $ZSH_CUSTOM/plugins/myplugin | subenv
$HOME/.zsh/custom/plugins/myplugin
%
```

## Teardown

```zsh
% # todo
%
```
