# antidote path tests

## Setup

```zsh
% source ./tests/_setup.zsh
% source ./antidote.zsh
%
```

## Path Command

`antidote-path` prints path to bundle.

```zsh
% antidote path foo/bar &>/dev/null  #=> --exit 0
% antidote path foo/bar | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar
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
% antidote list -s | antidote path | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-bar-SLASH-baz
$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar
$ANTIDOTE_HOME/git-AT-github.com-COLON-baz-SLASH-qux
$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmy-SLASH-ohmy
$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-romkatv-SLASH-zsh-defer
%
```

`antidote-path` expands vars

```zsh
% ZSH_CUSTOM=$ZDOTDIR/custom
% antidote path '$ZSH_CUSTOM/plugins/myplugin' | subenv
$ZDOTDIR/custom/plugins/myplugin
%
```

## Teardown

```zsh
% t_teardown
%
```
