#!/usr/bin/env bats
# antidote update tests (ported from tests/test_cmd_update.md)

load helpers/common

setup() {
  antidote_common_setup
  antidote_test_home
  ZSTYLES="zstyle ':antidote:test:version' show-sha off
zstyle ':antidote:test:git' autostash off"
  BAZDIR="$AHOME/fakegitsite.com/foo/baz"
  antidote_clone_fixtures
}

# Roll foo/baz back one commit so the remote is ahead. Clones are
# depth-1, so unshallow first.
rollback_foo_baz() {
  tgit -C "$BAZDIR" fetch --quiet --unshallow
  tgit -C "$BAZDIR" reset --quiet --hard HEAD~1
}

# The full update run is the command's output contract.
@test "update checks every cloned bundle" {
  run antidote update
  expect "Updating bundles...
antidote: checking for updates: bar/baz
antidote: checking for updates: foo/bar
antidote: checking for updates: foo/baz
antidote: checking for updates: git@fakegitsite.com:foo/qux
antidote: checking for updates: getantidote/zsh-defer
antidote: checking for updates: ohmy/ohmy
Waiting for bundle updates to complete...

Bundle updates complete."
}

@test "dry run reports an available update without applying it" {
  rollback_foo_baz
  local sha_before
  sha_before=$(git -C "$BAZDIR" rev-parse --short HEAD)
  run antidote update --dry-run
  [[ "$output" == *"antidote: update available: foo/baz bde701c -> 98cdde2"* ]]
  run git -C "$BAZDIR" rev-parse --short HEAD
  [ "$output" = "$sha_before" ]
}

@test "update pulls a rolled-back bundle to the latest commit" {
  rollback_foo_baz
  run antidote update
  [[ "$output" == *"antidote: updated: foo/baz bde701c -> 98cdde2"* ]]
  run git -C "$BAZDIR" rev-parse --short HEAD
  [ "$output" = "98cdde2" ]
}

# Update succeeds despite a dirty working tree, preserving both tracked
# changes and untracked files (autostash).
@test "update autostashes dirty working trees" {
  ZSTYLES="zstyle ':antidote:test:version' show-sha off
zstyle ':antidote:test:git' autostash on"
  rollback_foo_baz
  echo "junk" >>"$BAZDIR/baz.plugin.zsh"
  echo "untracked" >"$BAZDIR/untracked.txt"
  run antidote update
  [[ "$output" == *"antidote: updated: foo/baz bde701c -> 98cdde2"* ]]
  run grep -c junk "$BAZDIR/baz.plugin.zsh"
  [ "$output" = "1" ]
  [ -f "$BAZDIR/untracked.txt" ]
}

# Self-update runs in the parent shell (functions/antidote-update), so
# these two need a session. The prelude builds a fake antidote checkout
# so the git pull outcome is deterministic and offline; the session
# swaps in that checkout's antidote-update before calling it.
fake_checkout_prelude='zstyle ":antidote:test:version" show-sha off
fake=$HOME/fake-antidote
mkdir -p $fake
cp -r $T_PRJDIR/functions $fake/functions
cp $T_PRJDIR/antidote.zsh $fake/antidote.zsh
command git -C $fake init --quiet
use_fake_update() { fpath=($fake/functions $fpath); unfunction antidote-update; autoload -Uz $fake/functions/antidote-update }'

@test "self-update succeeds with a reachable origin" {
  SESSION_PRELUDE="$fake_checkout_prelude
command git -C \$fake add -A
command git -C \$fake -c user.email=test@test -c user.name=test commit --quiet -m init
command git clone --quiet \$fake \$fake-clone 2>/dev/null
fake=\$fake-clone"
  run_session <<'EOS'
( use_fake_update; antidote-update --self ); echo "exit: $?"
EOS
  expect "Updating antidote...
antidote self-update complete.

antidote version $EXPECTED_VERSION
exit: 0"
}

# A repo with no remote makes the pull fail.
@test "self-update failure reports an error" {
  SESSION_PRELUDE="$fake_checkout_prelude"
  run_session <<'EOS'
( use_fake_update; antidote-update --self 2>&1 ); echo "exit: $?"
EOS
  expect "Updating antidote...
antidote: self-update failed.
exit: 1"
}
