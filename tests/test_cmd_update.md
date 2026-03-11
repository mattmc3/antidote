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

## Teardown

```zsh
% t_teardown
%
```
