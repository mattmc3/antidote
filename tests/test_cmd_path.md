# antidote path tests

## Setup

```zsh
% source ./tests/__init__.zsh
% t_setup
%
```

Clone the standard test bundles:

```zsh
% antidote bundle <$ZDOTDIR/.base_test_fixtures.txt &>/dev/null
%
```

## Path Command

`antidote-path` prints path to bundle.

```zsh
% antidote path foo/bar &>/dev/null  #=> --exit 0
% antidote path foo/bar | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/fakegitsite.com/foo/bar
%
```

`antidote-path` fails on missing bundles

```zsh
% antidote path bar/foo &>/dev/null  #=> --exit 1
% antidote path bar/foo; err=$?
antidote: error: bar/foo does not exist in cloned paths
% echo $err
1
%
```

`antidote-path` accepts piped input

```zsh
% antidote list | antidote path | sort | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/fakegitsite.com/bar/baz
$ANTIDOTE_HOME/fakegitsite.com/foo/bar
$ANTIDOTE_HOME/fakegitsite.com/foo/baz
$ANTIDOTE_HOME/fakegitsite.com/foo/qux
$ANTIDOTE_HOME/fakegitsite.com/getantidote/zsh-defer
$ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy
%
```

`antidote-path` expands vars

```zsh
% ZSH_CUSTOM=$ZDOTDIR/custom
% antidote path '$ZSH_CUSTOM/plugins/myplugin' | subenv
$HOME/.zsh/custom/plugins/myplugin
%
```

## Teardown

```zsh
% t_teardown
%
```
