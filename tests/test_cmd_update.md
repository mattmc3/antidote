# antidote update tests

## Setup

```zsh
% source ./tests/__init__.zsh
% t_setup
%
```

## Update

```zsh
% antidote update
Updating bundles...
antidote: checking for updates: https://github.com/foo/bar
antidote: checking for updates: https://github.com/foo/baz
antidote: checking for updates: git@github.com:foo/qux
antidote: checking for updates: https://github.com/getantidote/zsh-defer
antidote: checking for updates: https://github.com/ohmy/ohmy
Waiting for bundle updates to complete...

Bundle updates complete.

Updating antidote...
antidote self-update complete.

antidote version 1.9.10 (abcd123)
%
```

## Teardown

```zsh
% t_teardown
%
```
