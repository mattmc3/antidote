# antidote update tests

## Setup

```zsh
% source ./tests/__init__.zsh
% t_setup
% antidote bundle <$ZDOTDIR/.base_test_fixtures.txt &>/dev/null
%
```

## Update

```zsh
% zstyle ':antidote:test:version' show-sha off
% zstyle ':antidote:test:git' autostash off
% antidote update --bundles
Updating bundles...
antidote: checking for updates: https://fakegitsite.com/bar/baz
antidote: checking for updates: https://fakegitsite.com/foo/bar
antidote: checking for updates: https://fakegitsite.com/foo/baz
antidote: checking for updates: git@fakegitsite.com:foo/qux
antidote: checking for updates: https://fakegitsite.com/getantidote/zsh-defer
antidote: checking for updates: https://fakegitsite.com/ohmy/ohmy
Waiting for bundle updates to complete...

Bundle updates complete.

%
```

## Dry Run

Roll back foo/baz by one commit so the remote is ahead:

```zsh
% bundledir=$ANTIDOTE_HOME/fakegitsite.com/foo/baz
% oldsha=$(command git -C $bundledir rev-parse --short HEAD)
% command git -C $bundledir reset --quiet --hard HEAD~1
% newsha=$(command git -C $bundledir rev-parse --short HEAD)
% [[ "$oldsha" != "$newsha" ]] && echo "rolled back"
rolled back
%
```

Dry run should report an available update but not change the SHA:

```zsh
% sha_before=$(command git -C $bundledir rev-parse --short HEAD)
% antidote update --bundles --dry-run 2>/dev/null | grep "foo/baz"
antidote: checking for updates: https://fakegitsite.com/foo/baz
Bundle foo/baz update check complete.
antidote: update available: https://fakegitsite.com/foo/baz bde701c -> 98cdde2
% sha_after=$(command git -C $bundledir rev-parse --short HEAD)
% [[ "$sha_before" == "$sha_after" ]] && echo "no changes made"
no changes made
%
```

A real update should actually change the SHA:

```zsh
% antidote update --bundles 2>/dev/null | grep "foo/baz"
antidote: checking for updates: https://fakegitsite.com/foo/baz
Bundle foo/baz update check complete.
antidote: updated: https://fakegitsite.com/foo/baz bde701c -> 98cdde2
% sha_final=$(command git -C $bundledir rev-parse --short HEAD)
% [[ "$sha_final" == "$oldsha" ]] && echo "updated to latest"
updated to latest
%
```

## Update writes lockfile

```zsh
% grep "foo/baz" $ZDOTDIR/.zsh_plugins.lock
zstyle ':antidote:bundle:fakegitsite.com/foo/baz' lock-commit '98cdde20c338bdb4df6efefd7f812d38ecc62b70'
%
```

## Dry run does not update lockfile

```zsh
% command git -C $bundledir reset --quiet --hard HEAD~1
% antidote update --bundles --dry-run &>/dev/null
% grep "foo/baz" $ZDOTDIR/.zsh_plugins.lock
zstyle ':antidote:bundle:fakegitsite.com/foo/baz' lock-commit '98cdde20c338bdb4df6efefd7f812d38ecc62b70'
%
```

## Teardown

```zsh
% t_teardown
%
```
