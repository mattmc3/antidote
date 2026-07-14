#!/usr/bin/env bats
# antidote snapshot tests (ported from tests/test_cmd_snapshot.md)

load helpers/common

setup() {
  antidote_common_setup
  antidote_test_home
  SNAP_DIR="$TESTHOME/.antidote-snapshots"
  ZSTYLES="zstyle ':antidote:snapshot' dir $SNAP_DIR
zstyle ':antidote:fzf' cmd ''
zstyle ':antidote:test:version' show-sha off
zstyle ':antidote:test:git' autostash off"
  antidote_clone_fixtures
}

save_at_epoch() {
  ZSTYLES="$ZSTYLES
zstyle ':antidote:test:snapshot' epoch $1" antidote snapshot save >/dev/null
}

@test "snapshot save creates one snapshot file" {
  run antidote snapshot save
  [[ "$output" == *"Snapshot saved:"* ]]
  run ls "$SNAP_DIR"
  [ "${#lines[@]}" -eq 1 ]
}

@test "snapshot file has comment headers" {
  antidote snapshot save >/dev/null
  run head -3 "$SNAP_DIR"/snapshot-*.txt
  [ "${lines[0]}" = "# antidote snapshot" ]
  [[ "${lines[1]}" =~ ^"# version: "[0-9]+\.[0-9]+\.[0-9]+$ ]]
  [[ "${lines[2]}" =~ ^"# date: "[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]
}

@test "snapshot body matches the expected fixture" {
  antidote snapshot save >/dev/null
  run diff <(tail -n +4 "$SNAP_DIR"/snapshot-*.txt) "$PRJDIR/tests/testdata/.zsh_plugins.snapshot.txt"
  [ "$status" -eq 0 ]
}

@test "snapshot home prints the snapshot dir" {
  run antidote snapshot home
  expect "$SNAP_DIR"
}

@test "snapshot list shows saved snapshots" {
  save_at_epoch 1000000001
  run antidote snapshot list
  [[ "$output" == "$SNAP_DIR/snapshot-"*.txt ]]
}

# Update auto-saves a new snapshot capturing the restored state.
@test "update auto-saves a snapshot" {
  save_at_epoch 1000000001
  tgit -C "$AHOME/fakegitsite.com/foo/baz" fetch --quiet --unshallow
  tgit -C "$AHOME/fakegitsite.com/foo/baz" reset --quiet --hard HEAD~1
  ZSTYLES="$ZSTYLES
zstyle ':antidote:test:snapshot' epoch 1000000002" antidote update &>/dev/null
  run ls "$SNAP_DIR"
  [ "${#lines[@]}" -eq 2 ]
  run diff <(tail -n +4 "$SNAP_DIR/snapshot-20010909-014642Z.txt") "$PRJDIR/tests/testdata/.zsh_plugins.snapshot.txt"
  [ "$status" -eq 0 ]
}

@test "snapshot restore succeeds from a saved snapshot" {
  save_at_epoch 1000000001
  run antidote snapshot restore "$SNAP_DIR"/snapshot-*.txt
  [ "$status" -eq 0 ]
}

@test "dynamic mode skips snapshot save" {
  EXTRA_ENV="ANTIDOTE_DYNAMIC=true"
  run antidote snapshot save
  expect ""
  [ ! -d "$SNAP_DIR" ]
}

# Disabling autosnapshot prevents auto-save on update, but explicit
# save still works.
@test "autosnapshot disabled skips save on update" {
  ZSTYLES="$ZSTYLES
zstyle ':antidote:snapshot:automatic' enabled no"
  antidote update &>/dev/null
  [ ! -d "$SNAP_DIR" ]
  run antidote snapshot save
  [[ "$output" == *"Snapshot saved:"* ]]
}

@test "snapshot dir zstyle relocates snapshots" {
  ZSTYLES="zstyle ':antidote:snapshot' dir $TESTHOME/.antidote-snaps"
  run antidote snapshot save
  [[ "$output" == *"$TESTHOME/.antidote-snaps"* ]]
  [ -d "$TESTHOME/.antidote-snaps" ]
}

@test "pruning keeps only the configured max snapshots" {
  ZSTYLES="$ZSTYLES
zstyle ':antidote:snapshot' max 3"
  local epoch
  for epoch in 1000000001 1000000002 1000000003 1000000004 1000000005; do
    save_at_epoch $epoch
  done
  run ls "$SNAP_DIR"
  [ "${#lines[@]}" -eq 3 ]
}

@test "snapshot --help and unknown subcommands" {
  run antidote snapshot --help
  [[ "$output" == *snapshot* ]]
  run antidote snapshot foo
  [ "$status" -eq 1 ]
  expect "antidote: snapshot: unknown subcommand 'foo'"
}

@test "restore without a file and without a picker errors" {
  save_at_epoch 1000000001
  run antidote snapshot restore
  [ "$status" -eq 1 ]
  expect "antidote: snapshot: no snapshot file specified (use 'antidote snapshot list' to see available snapshots)"
}

@test "restore with a picker but no snapshots errors" {
  ZSTYLES="zstyle ':antidote:snapshot' dir $SNAP_DIR
zstyle ':antidote:fzf' cmd $PRJDIR/tests/bin/mock_fzf"
  mkdir -p "$SNAP_DIR"
  run antidote snapshot restore
  [ "$status" -eq 1 ]
  expect "antidote: snapshot: no snapshots found"
}

@test "restore with a missing file errors" {
  run antidote snapshot restore /nonexistent/snapshot.txt
  [ "$status" -eq 1 ]
  expect "antidote: snapshot: file not found '/nonexistent/snapshot.txt'"
}

@test "remove deletes the given snapshot file" {
  save_at_epoch 1000000001
  save_at_epoch 1000000002
  run antidote snapshot remove "$SNAP_DIR/snapshot-20010909-014641Z.txt"
  [[ "$output" == Removed:* ]]
  run ls "$SNAP_DIR"
  [ "${#lines[@]}" -eq 1 ]
}

@test "remove errors: missing file, no picker, no snapshots" {
  run antidote snapshot remove /nonexistent/snapshot.txt
  [[ "$output" == *"file not found '/nonexistent/snapshot.txt'"* ]]
  save_at_epoch 1000000001
  run antidote snapshot remove
  expect "antidote: snapshot: no snapshot file specified (use 'antidote snapshot list' to see available snapshots)"
  rm -rf "$SNAP_DIR"; mkdir -p "$SNAP_DIR"
  ZSTYLES="zstyle ':antidote:snapshot' dir $SNAP_DIR
zstyle ':antidote:fzf' cmd $PRJDIR/tests/bin/mock_fzf"
  run antidote snapshot remove
  expect "antidote: snapshot: no snapshots found"
}

@test "snapshot list is newest first" {
  save_at_epoch 1000000001
  save_at_epoch 1000000002
  save_at_epoch 1000000003
  run antidote snapshot list
  [ "${lines[0]}" = "$SNAP_DIR/snapshot-20010909-014643Z.txt" ]
  [ "${lines[2]}" = "$SNAP_DIR/snapshot-20010909-014641Z.txt" ]
}

@test "restore returns a rolled-back repo to the snapshotted SHA" {
  local bundledir="$AHOME/fakegitsite.com/foo/baz"
  tgit -C "$bundledir" fetch --quiet --unshallow
  local expected_sha
  expected_sha=$(git -C "$bundledir" rev-parse HEAD)
  save_at_epoch 1000000001
  git -C "$bundledir" reset --quiet --hard HEAD~1
  antidote snapshot restore "$SNAP_DIR"/snapshot-*.txt &>/dev/null
  run git -C "$bundledir" rev-parse HEAD
  [ "$output" = "$expected_sha" ]
}
