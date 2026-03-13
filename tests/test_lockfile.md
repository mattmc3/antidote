# antidote lockfile tests

## Setup

```zsh
% source ./tests/__init__.zsh
% t_setup
%
```

## Lockfile is created after bundle

```zsh
% echo "foo/bar" | antidote bundle &>/dev/null
% [[ -f $ZDOTDIR/.zsh_plugins.lock ]] && echo "lockfile exists"
lockfile exists
%
```

## Lockfile contains expected zstyle with path relative to ANTIDOTE_HOME

```zsh
% grep "foo/bar" $ZDOTDIR/.zsh_plugins.lock
zstyle ':antidote:bundle:fakegitsite.com/foo/bar' lock-commit '400b29a76d68fd7c40bc7c0460424ab089b1e68a'
%
```

## Lockfile has shebang

```zsh
% head -1 $ZDOTDIR/.zsh_plugins.lock
#!/usr/bin/env zsh
%
```

## Lockfile is sourceable

```zsh
% source $ZDOTDIR/.zsh_plugins.lock
% zstyle -s ':antidote:bundle:fakegitsite.com/foo/bar' lock-commit REPLY && echo $REPLY
400b29a76d68fd7c40bc7c0460424ab089b1e68a
%
```

## Lockfile matches expected output for base fixtures

```zsh
% antidote bundle <$ZDOTDIR/.base_test_fixtures.txt &>/dev/null
% diff $ZDOTDIR/.zsh_plugins.lock $T_TESTDATA/.zsh_plugins.lock
%
```

## Lockfile only contains current bundles (no stale entries)

After purging a bundle and re-bundling, the lockfile should not contain the purged bundle.

```zsh
% antidote purge foo/bar &>/dev/null
% echo "foo/baz" | antidote bundle &>/dev/null
% grep "foo/bar" $ZDOTDIR/.zsh_plugins.lock | wc -l | tr -d ' '
0
%
```

## Lockfile enforces locked SHA on fresh clone

Write a lockfile pointing foo/baz at an older commit, purge it,
then re-bundle. The clone should checkout the locked SHA, not HEAD.

```zsh
% antidote purge foo/baz &>/dev/null
% print "zstyle ':antidote:bundle:fakegitsite.com/foo/baz' lock-commit 'bde701cd12dbdf921e3f44cc23864a08c5ba0dd2'" >| $ZDOTDIR/.zsh_plugins.lock
% echo "foo/baz" | antidote bundle &>/dev/null
% bundledir=$ANTIDOTE_HOME/fakegitsite.com/foo/baz
% command git -C $bundledir rev-parse HEAD
bde701cd12dbdf921e3f44cc23864a08c5ba0dd2
%
```

## Pin overrides lockfile

Write a lockfile pointing to v1.1.0, but pin to v1.0.0. Pin wins.

```zsh
% print "zstyle ':antidote:bundle:fakegitsite.com/pintest/pinme' lock-commit 'c87216c18d3f0301fa1ed669b6c1ad76056271ca'" >| $ZDOTDIR/.zsh_plugins.lock
% echo "pintest/pinme pin:v1.0.0" | antidote bundle &>/dev/null
% bundledir=$ANTIDOTE_HOME/fakegitsite.com/pintest/pinme
% command git -C $bundledir rev-parse HEAD
64642c5691051ba0d82f5bda60b745f6fd042325
%
```

## Lockfile disabled via zstyle

```zsh
% zstyle ':antidote:lockfile' disabled yes
% rm -f $ZDOTDIR/.zsh_plugins.lock
% [[ ! -f $ZDOTDIR/.zsh_plugins.lock ]] && echo "deleted"
deleted
% echo "foo/baz" | antidote bundle &>/dev/null
% [[ ! -f $ZDOTDIR/.zsh_plugins.lock ]] && echo "no lockfile"
no lockfile
% zstyle -d ':antidote:lockfile' disabled
%
```

## Teardown

```zsh
% t_teardown
%
```
