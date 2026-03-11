# antidote installs tests

## Setup

```zsh
% source ./tests/__init__.zsh
% t_setup
% antidote bundle <$ZDOTDIR/.base_test_fixtures.txt &>/dev/null
%
```

## Install Command

`antidote install` requires a `<bundle>` argument.

```zsh
% antidote install  #=> --exit 1
antidote: error: required argument 'bundle' not provided, try --help
%
```

Trying to install an existing bundle fails.

```zsh
% antidote install foo/bar &>/dev/null  #=> --exit 1
% antidote install foo/bar 2>&1 | subenv HOME >&2
antidote: error: foo/bar already installed: $HOME/.cache/antidote/fakegitsite.com/foo/bar
%
```

Trying to install a non-existent bundle fails.

```zsh
% antidote install does-not/exist 2>&1  #=> --exit 1
# antidote cloning does-not/exist...
antidote: unable to install bundle 'does-not/exist'.
%
```

Install a bundle

```zsh
% antidote install themes/purify | subenv ZDOTDIR
# antidote cloning themes/purify...
Adding bundle to '$ZDOTDIR/.zsh_plugins.txt':
themes/purify
% tail -n 1 $ZDOTDIR/.zsh_plugins.txt
themes/purify
%
```

Install a complicated bundle

```zsh
% antidote install --kind fpath --conditional is-macos themes/ohmytheme | subenv ZDOTDIR
# antidote cloning themes/ohmytheme...
Adding bundle to '$ZDOTDIR/.zsh_plugins.txt':
themes/ohmytheme kind:fpath conditional:is-macos
% tail -n 1 $ZDOTDIR/.zsh_plugins.txt
themes/ohmytheme kind:fpath conditional:is-macos
%
```

## Teardown

```zsh
% t_teardown
%
```
