# antidote snapshot tests

## Setup

```zsh
% source ./tests/__init__.zsh
% t_setup
% antidote bundle <$ZDOTDIR/.base_test_fixtures.txt &>/dev/null
% SNAP_DIR=$HOME/.local/share/antidote/snapshots
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
% sed -n '2p' $snapshot_file | grep -c "# version: 2.0.0"
1
% sed -n '3p' $snapshot_file | grep -cE "# date: [0-9]{4}-[0-9]{2}-[0-9]{2}T"
1
%
```

The snapshot body matches the expected fixture:

```zsh
% diff <(tail -n +4 $snapshot_file) $T_TESTDATA/.zsh_plugins.snapshot.txt
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
% sleep 1
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
% antidote snapshot save >/dev/null && sleep 1
% antidote snapshot save >/dev/null && sleep 1
% antidote snapshot save >/dev/null && sleep 1
% antidote snapshot save >/dev/null && sleep 1
% antidote snapshot save >/dev/null
% ls $HOME/.antidote-prune-test/snapshot-*.txt | wc -l | tr -d ' '
3
% zstyle -d ':antidote:snapshot' max
% zstyle -d ':antidote:snapshot' dir
%
```

## Teardown

```zsh
% t_teardown
%
```
