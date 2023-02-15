# antidote purge tests

## Setup

```zsh
% TESTDIR=$PWD/tests
% source $TESTDIR/scripts/setup.zsh
%
```

## Purge Command

`antidote purge` requires a `<bundle>` argument.

```zsh
% antidote purge &>/dev/null  #=> --exit 1
% antidote purge
antidote: error: required argument 'bundle' not provided, try --help
%
```

Trying to purge a missing bundle fails.

```zsh
% antidote purge bar/foo &>/dev/null  #=> --exit 1
% antidote purge bar/foo 2>&1 | subvar ANTIDOTE_HOME >&2
antidote: error: bar/foo does not exist at the expected location: $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-bar-SLASH-foo
%
```

Purging a bundle deletes the directory and comments out instances of the bundle in `.zsh_plugins.txt`.

```zsh
% # bundle dir exists
% bundledir=$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar
% test -d $bundledir  #=> --exit 0
% # purge works
% antidote purge foo/bar | subvar ZDOTDIR
Removed 'foo/bar'.
Bundle 'foo/bar' was commented out in '$ZDOTDIR/.zsh_plugins.txt'.
% # bundle dir was removed
% test -d $bundledir  #=> --exit 1
% cat $ZDOTDIR/.zsh_plugins.txt  #=> --file ./testdata/.zsh_plugins_purged.txt
%
```

## Teardown

```zsh
% t_teardown
%
```
