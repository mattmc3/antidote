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
antidote: checking for updates: bar/baz
antidote: checking for updates: foo/bar
antidote: checking for updates: foo/baz
antidote: checking for updates: git@fakegitsite.com:foo/qux
antidote: checking for updates: getantidote/zsh-defer
antidote: checking for updates: ohmy/ohmy
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
antidote: checking for updates: foo/baz
Bundle foo/baz update check complete.
antidote: update available: foo/baz bde701c -> 98cdde2
% sha_after=$(command git -C $bundledir rev-parse --short HEAD)
% [[ "$sha_before" == "$sha_after" ]] && echo "no changes made"
no changes made
%
```

A real update should actually change the SHA:

```zsh
% antidote update --bundles 2>/dev/null | grep "foo/baz"
antidote: checking for updates: foo/baz
Bundle foo/baz update check complete.
antidote: updated: foo/baz bde701c -> 98cdde2
% sha_final=$(command git -C $bundledir rev-parse --short HEAD)
% [[ "$sha_final" == "$oldsha" ]] && echo "updated to latest"
updated to latest
%
```

## Update with dirty working tree (autostash)

Roll back foo/baz by one commit, dirty a tracked file, and add an untracked file:

```zsh
% bundledir=$ANTIDOTE_HOME/fakegitsite.com/foo/baz
% command git -C $bundledir reset --quiet --hard HEAD~1
% echo "junk" >> $bundledir/baz.plugin.zsh
% echo "untracked" > $bundledir/untracked.txt
% [[ -n "$(command git -C $bundledir status --porcelain)" ]] && echo "dirty"
dirty
%
```

Update should succeed and advance the SHA despite the dirty working tree:

```zsh
% zstyle ':antidote:test:git' autostash on
% sha_before=$(command git -C $bundledir rev-parse --short HEAD)
% antidote update --bundles 2>/dev/null | grep "foo/baz"
antidote: checking for updates: foo/baz
Bundle foo/baz update check complete.
antidote: updated: foo/baz bde701c -> 98cdde2
% sha_after=$(command git -C $bundledir rev-parse --short HEAD)
% [[ "$sha_before" != "$sha_after" ]] && echo "updated"
updated
%
```

The tracked modification and untracked file should still be present after the update:

```zsh
% grep -q "junk" $bundledir/baz.plugin.zsh && echo "tracked change preserved"
tracked change preserved
% [[ -f $bundledir/untracked.txt ]] && echo "untracked file preserved"
untracked file preserved
%
```

## Teardown

```zsh
% t_teardown
%
```
