# antidote path tests

## Setup

```zsh
% source ./tests/_setup.zsh
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

## Teardown

```zsh
% t_teardown
%
```
