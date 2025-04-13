# antidote purge tests

## Setup

```zsh
% source ./tests/__init__.zsh
% t_setup
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
% antidote purge bar/foo 2>&1 | subenv ANTIDOTE_HOME >&2
antidote: error: bar/foo does not exist at the expected location: $ANTIDOTE_HOME/bar/foo
%
```

Purging a bundle deletes the directory and comments out instances of the bundle in `.zsh_plugins.txt`.

```zsh
% # bundle dir exists
% bundledir=$ANTIDOTE_HOME/foo/bar
% test -d $bundledir  #=> --exit 0
% # purge works
% antidote purge foo/bar | subenv ZDOTDIR
Removed 'foo/bar'.
Bundle 'foo/bar' was commented out in '$ZDOTDIR/.zsh_plugins.txt'.
% # bundle dir was removed
% test -d $bundledir  #=> --exit 1
% cat $ZDOTDIR/.zsh_plugins.txt  #=> --file ./testdata/.zsh_plugins_purged.txt
%
```

Test that `antidote purge --all` aborts when told "no".

```zsh
% function test_exists { [[ -e "$1" ]] }
% zstyle ':antidote:purge:all' answer 'n'
% antidote purge --all  #=> --exit 1
% antidote list | subenv ANTIDOTE_HOME
git@github.com:foo/qux                                           $ANTIDOTE_HOME/foo/qux
https://github.com/foo/baz                                       $ANTIDOTE_HOME/foo/baz
https://github.com/getantidote/zsh-defer                         $ANTIDOTE_HOME/getantidote/zsh-defer
https://github.com/ohmy/ohmy                                     $ANTIDOTE_HOME/ohmy/ohmy
%
```

Test that `antidote purge --all` does the work when told "yes".

```zsh
% function test_exists { [[ -e "$1" ]] }
% zstyle ':antidote:purge:all' answer 'y'
% antidote purge --all | tail -n 1
Antidote purge complete. Be sure to start a new Zsh session.
% antidote list | wc -l | awk '{print $1}'
0
%
```

## Teardown

```zsh
% t_teardown
%
```
