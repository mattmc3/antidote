# antidote snapshot tests

## Setup

```zsh
% source ./tests/__init__.zsh
% t_setup
% antidote bundle <$ZDOTDIR/.base_test_fixtures.txt &>/dev/null
% SNAP_DIR=$HOME/.antidote-snapshots
% zstyle ':antidote:fzf' cmd ''
% zstyle ':antidote:snapshot' dir $SNAP_DIR
% source $T_PRJDIR/antidote.zsh
%
```

## Snapshot save

Saving a snapshot creates a file in the snapshot directory:

```zsh
% antidote snapshot save | grep -c "Snapshot saved:"
1
% ls $SNAP_DIR/snapshot-*.txt | wc -l | tr -d ' '
1
%
```

The snapshot file has comment headers:

```zsh
% snapshot_file=$(ls $SNAP_DIR/snapshot-*.txt)
% head -1 $snapshot_file
# antidote snapshot
% sed -n '2p' $snapshot_file | grep -cE '# version: [0-9]+\.[0-9]+\.[0-9]+'
1
% sed -n '3p' "$snapshot_file" | grep -cE '# date: [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z'
1
%
```

The snapshot body matches the expected fixture:

```zsh
% diff <(tail -n +4 $snapshot_file) $T_TESTDATA/.zsh_plugins.snapshot.txt
%
```

## Snapshot home

```zsh
% antidote snapshot home | subenv
$HOME/.antidote-snapshots
%
```

## Snapshot list

```zsh
% antidote snapshot list | grep -c "snapshot-"
1
%
```

## Snapshot save after update

Unshallow foo/baz so we can roll it back, then update. The update should auto-save a new snapshot:

```zsh
% zstyle ':antidote:test:version' show-sha off
% zstyle ':antidote:test:git' autostash off
% bundledir=$ANTIDOTE_HOME/fakegitsite.com/foo/baz
% command git -C $bundledir fetch --quiet --unshallow 2>/dev/null; true
% oldsha=$(command git -C $bundledir rev-parse HEAD)
% command git -C $bundledir reset --quiet --hard HEAD~1
% newsha=$(command git -C $bundledir rev-parse HEAD)
% [[ "$oldsha" != "$newsha" ]] && echo "rolled back"
rolled back
% zstyle ':antidote:test:snapshot' epoch 1000000002
% antidote update --bundles &>/dev/null
% ls $SNAP_DIR/snapshot-*.txt | wc -l | tr -d ' '
2
%
```

After update, the latest snapshot should match the original fixture (SHA restored):

```zsh
% latest=$(ls $SNAP_DIR/snapshot-*.txt | tail -1)
% diff <(tail -n +4 $latest) $T_TESTDATA/.zsh_plugins.snapshot.txt
%
```

## Snapshot restore

Restore from the latest snapshot re-bundles everything:

```zsh
% antidote snapshot restore $latest &>/dev/null
% echo $?
0
%
```

## Dynamic mode skips snapshots

```zsh
% count_before=$(ls $SNAP_DIR/snapshot-*.txt 2>/dev/null | wc -l | tr -d ' ')
% ANTIDOTE_DYNAMIC=true antidote snapshot save
% count_after=$(ls $SNAP_DIR/snapshot-*.txt 2>/dev/null | wc -l | tr -d ' ')
% [[ "$count_before" == "$count_after" ]] && echo "no new snapshot"
no new snapshot
%
```

## Autosnapshot disabled

Disabling autosnapshot prevents auto-snapshot on update, but explicit save still works:

```zsh
% zstyle ':antidote:snapshot:automatic' enabled no
% zstyle ':antidote:snapshot' dir $HOME/.antidote-disabled-test
% source $T_PRJDIR/antidote.zsh
% antidote snapshot save | grep -c "Snapshot saved:"
1
% zstyle -d ':antidote:snapshot:automatic' enabled
% zstyle -d ':antidote:snapshot' dir
%
```

## Custom snapshot directory

```zsh
% zstyle ':antidote:snapshot' dir $HOME/.antidote-snaps
% source $T_PRJDIR/antidote.zsh
% antidote snapshot save | grep -c "antidote-snaps"
1
% [[ -d $HOME/.antidote-snaps ]] && echo "custom dir exists"
custom dir exists
% zstyle -d ':antidote:snapshot' dir
%
```

## Snapshot pruning

Save snapshots over the max and verify pruning keeps only the max:

```zsh
% zstyle ':antidote:snapshot' max 3
% zstyle ':antidote:snapshot' dir $HOME/.antidote-prune-test
% source $T_PRJDIR/antidote.zsh
% zstyle ':antidote:test:snapshot' epoch 1000000001; antidote snapshot save >/dev/null
% zstyle ':antidote:test:snapshot' epoch 1000000002; antidote snapshot save >/dev/null
% zstyle ':antidote:test:snapshot' epoch 1000000003; antidote snapshot save >/dev/null
% zstyle ':antidote:test:snapshot' epoch 1000000004; antidote snapshot save >/dev/null
% zstyle ':antidote:test:snapshot' epoch 1000000005; antidote snapshot save >/dev/null
% ls $HOME/.antidote-prune-test/snapshot-*.txt | wc -l | tr -d ' '
3
% zstyle -d ':antidote:snapshot' max
% zstyle -d ':antidote:snapshot' dir
% zstyle -d ':antidote:test:snapshot' epoch
%
```

## Help flag

```zsh
% antidote snapshot --help 2>&1 | grep -c "snapshot"  #=> --exit 0
%
```

## Unknown subcommand

```zsh
% antidote snapshot foo 2>&1
antidote: snapshot: unknown subcommand 'foo'
%
```

## Restore error: no file specified (without fzf)

```zsh
% zstyle ':antidote:snapshot' dir $HOME/.antidote-empty-snaps
% source $T_PRJDIR/antidote.zsh
% mkdir -p $HOME/.antidote-empty-snaps
% antidote snapshot save >/dev/null
% path=(${path:#*fzf*})
% unhash -f fzf 2>/dev/null; true
% antidote snapshot restore 2>&1 | head -1
antidote: snapshot: no snapshot file specified (use 'antidote snapshot list' to see available snapshots)
% zstyle -d ':antidote:snapshot' dir
%
```

## Restore error: no snapshots found

```zsh
% zstyle ':antidote:snapshot' dir $HOME/.antidote-no-snaps
% zstyle ':antidote:fzf' cmd $T_PRJDIR/tests/bin/mock_fzf
% source $T_PRJDIR/antidote.zsh
% mkdir -p $HOME/.antidote-no-snaps
% antidote snapshot restore 2>&1 | head -1
antidote: snapshot: no snapshots found
% zstyle -d ':antidote:snapshot' dir
% zstyle -d ':antidote:fzf' cmd
%
```

## Restore error: file not found

```zsh
% antidote snapshot restore /nonexistent/snapshot.txt 2>&1
antidote: snapshot: file not found '/nonexistent/snapshot.txt'
%
```

## Remove with file argument

```zsh
% zstyle ':antidote:snapshot' dir $HOME/.antidote-remove-test
% source $T_PRJDIR/antidote.zsh
% zstyle ':antidote:test:snapshot' epoch 1000000001; antidote snapshot save >/dev/null
% zstyle ':antidote:test:snapshot' epoch 1000000002; antidote snapshot save >/dev/null
% ls $HOME/.antidote-remove-test/snapshot-*.txt | wc -l | tr -d ' '
2
% snap=$(ls $HOME/.antidote-remove-test/snapshot-*.txt | head -1)
% antidote snapshot remove $snap | grep -c "Removed:"
1
% ls $HOME/.antidote-remove-test/snapshot-*.txt | wc -l | tr -d ' '
1
% zstyle -d ':antidote:snapshot' dir
% zstyle -d ':antidote:test:snapshot' epoch
%
```

## Remove error: file not found

```zsh
% antidote snapshot remove /nonexistent/snapshot.txt 2>&1
antidote: snapshot: file not found '/nonexistent/snapshot.txt'
%
```

## Remove error: no file specified (without fzf)

```zsh
% zstyle ':antidote:snapshot' dir $HOME/.antidote-remove-nofzf
% source $T_PRJDIR/antidote.zsh
% antidote snapshot save >/dev/null
% path=(${path:#*fzf*})
% unhash -f fzf 2>/dev/null; true
% antidote snapshot remove 2>&1 | head -1
antidote: snapshot: no snapshot file specified (use 'antidote snapshot list' to see available snapshots)
% zstyle -d ':antidote:snapshot' dir
%
```

## Remove error: no snapshots found

```zsh
% zstyle ':antidote:snapshot' dir $HOME/.antidote-remove-empty
% zstyle ':antidote:fzf' cmd $T_PRJDIR/tests/bin/mock_fzf
% source $T_PRJDIR/antidote.zsh
% mkdir -p $HOME/.antidote-remove-empty
% antidote snapshot remove 2>&1 | head -1
antidote: snapshot: no snapshots found
% zstyle -d ':antidote:fzf' cmd
%
```

## List order (newest first)

```zsh
% zstyle ':antidote:snapshot' dir $HOME/.antidote-order-test
% source $T_PRJDIR/antidote.zsh
% zstyle ':antidote:test:snapshot' epoch 1000000001; antidote snapshot save >/dev/null
% zstyle ':antidote:test:snapshot' epoch 1000000002; antidote snapshot save >/dev/null
% zstyle ':antidote:test:snapshot' epoch 1000000003; antidote snapshot save >/dev/null
% first=$(antidote snapshot list | head -1)
% last=$(antidote snapshot list | tail -1)
% [[ "$first" > "$last" ]] && echo "newest first"
newest first
% zstyle -d ':antidote:snapshot' dir
% zstyle -d ':antidote:test:snapshot' epoch
%
```

## Restore verifies repo SHAs

Roll back foo/baz, save a snapshot, then restore and verify the SHA matches:

```zsh
% zstyle ':antidote:snapshot' dir $HOME/.antidote-restore-test
% source $T_PRJDIR/antidote.zsh
% bundledir=$ANTIDOTE_HOME/fakegitsite.com/foo/baz
% command git -C $bundledir fetch --quiet --unshallow 2>/dev/null; true
% expected_sha=$(command git -C $bundledir rev-parse HEAD)
% antidote snapshot save >/dev/null
% command git -C $bundledir reset --quiet --hard HEAD~1
% rolled_sha=$(command git -C $bundledir rev-parse HEAD)
% [[ "$expected_sha" != "$rolled_sha" ]] && echo "rolled back"
rolled back
% snap=$(ls $HOME/.antidote-restore-test/snapshot-*.txt | tail -1)
% antidote snapshot restore $snap &>/dev/null
% actual_sha=$(command git -C $bundledir rev-parse HEAD)
% [[ "$actual_sha" == "$expected_sha" ]] && echo "restored"
restored
% zstyle -d ':antidote:snapshot' dir
%
```

## Teardown

```zsh
% t_teardown
%
```
