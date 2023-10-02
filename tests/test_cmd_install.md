# antidote installs tests

## Setup

```zsh
% source ./tests/_setup.zsh
% source ./antidote.zsh
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
% antidote install foo/bar 2>&1 | subenv ANTIDOTE_HOME >&2
antidote: error: foo/bar already installed: $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar
%
```

Install a bundle

```zsh
% antidote install rupa/z | subenv ZDOTDIR
# antidote cloning rupa/z...
Adding bundle to '$ZDOTDIR/.zsh_plugins.txt':
rupa/z
% tail -n 1 $ZDOTDIR/.zsh_plugins.txt
rupa/z
%
```

Install a complicated bundle

```zsh
% antidote install --path plugins/macos --conditional is-macos ohmyzsh/ohmyzsh | subenv ZDOTDIR
# antidote cloning ohmyzsh/ohmyzsh...
Adding bundle to '$ZDOTDIR/.zsh_plugins.txt':
ohmyzsh/ohmyzsh path:plugins/macos conditional:is-macos
% tail -n 1 $ZDOTDIR/.zsh_plugins.txt
ohmyzsh/ohmyzsh path:plugins/macos conditional:is-macos
%
```

## Teardown

```zsh
% t_teardown
%
```
