# antidote gist bundle tests

## Setup

```zsh
% TESTDATA=$T_PRJDIR/tests/testdata/real
% source ./tests/__init__.zsh
% t_setup_real
%
```

## Bundle a gist URL

Gist URLs have a single path segment (no user/repo), and should be treated as
valid URL bundles.

```zsh
% antidote bundle https://gist.github.com/mattmc3/6bc5646ae0fb7cc86502933ca6661d5c.git 2>&1 | head -1
# antidote cloning mattmc3/6bc5646ae0fb7cc86502933ca6661d5c...
% antidote path https://gist.github.com/mattmc3/6bc5646ae0fb7cc86502933ca6661d5c.git | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/mattmc3/6bc5646ae0fb7cc86502933ca6661d5c
% antidote list --url | grep gist
https://gist.github.com/mattmc3/6bc5646ae0fb7cc86502933ca6661d5c.git
%
```

## Teardown

```zsh
% t_teardown
%
```
