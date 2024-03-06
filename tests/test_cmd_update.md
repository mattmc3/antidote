# antidote update tests

## Setup

```zsh
% source ./tests/_setup.zsh
% source ./antidote.zsh
%
```

## Update

```zsh
% antidote update
Updating bundles...
antidote: checking for updates: git@github.com:baz/qux
antidote: checking for updates: https://github.com/bar/baz
antidote: checking for updates: https://github.com/foo/bar
antidote: checking for updates: https://github.com/ohmy/ohmy
antidote: checking for updates: https://github.com/romkatv/zsh-defer
Waiting for bundle updates to complete...

Bundle updates complete.

Updating antidote...
antidote self-update complete.

antidote version 1.9.6
%
```

## Teardown

```zsh
% t_teardown
%
```
