#!/usr/bin/env bats
# antidote update tests

load helpers/common

setup() {
  antidote_common_setup
  antidote_test_home
  ZSTYLES="zstyle ':antidote:test:version' show-sha off
zstyle ':antidote:test:git' autostash off"
  BAZDIR="$AHOME/fakegitsite.com/foo/baz"
  antidote_clone_fixtures
}

# Roll foo/baz back one commit so the remote is ahead. Needs history,
# so make sure the clone is deepened first.
rollback_foo_baz() {
  tgit_deepen "$BAZDIR"
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
  assert_output --partial "antidote: update available: foo/baz bde701c -> 98cdde2"
  run git -C "$BAZDIR" rev-parse --short HEAD
  assert_output "$sha_before"
}

# A real update clears the load marker and zcompiled files; a dry run
# must leave both in place.
@test "dry run leaves the load marker and zwc files alone" {
  touch "$AHOME/.antidote.load" "$BAZDIR/baz.plugin.zsh.zwc"
  run antidote update --dry-run
  assert_success
  [ -f "$AHOME/.antidote.load" ]
  [ -f "$BAZDIR/baz.plugin.zsh.zwc" ]
}

@test "update clears the load marker and zwc files" {
  touch "$AHOME/.antidote.load" "$BAZDIR/baz.plugin.zsh.zwc"
  run antidote update
  assert_success
  [ ! -e "$AHOME/.antidote.load" ]
  [ ! -e "$BAZDIR/baz.plugin.zsh.zwc" ]
}

@test "dry run does not write an autosnapshot" {
  local snapdir="$BATS_TEST_TMPDIR/snapshots"
  ZSTYLES="$ZSTYLES
zstyle ':antidote:snapshot' dir '$snapdir'
zstyle ':antidote:snapshot:automatic' enabled yes"

  run antidote update --dry-run
  assert_success
  [ ! -e "$snapdir" ]
}

# Deepening a clone is permanent, so a dry run must not do it. Clone one
# bundle shallow and hold it there, then drop the hold so a real update
# would deepen it, and check that only the real update does.
@test "dry run leaves a shallow clone shallow" {
  local dir="$AHOME/fakegitsite.com/pintest/pinme"
  local base="$ZSTYLES"
  ZSTYLES="$base
zstyle ':antidote:bundle:pintest/pinme' shallow yes"
  run antidote bundle 'pintest/pinme kind:clone'
  assert_success
  run git -C "$dir" rev-parse --is-shallow-repository
  assert_output "true"

  ZSTYLES="$base"
  run antidote update --dry-run
  assert_success
  run git -C "$dir" rev-parse --is-shallow-repository
  assert_output "true"

  run antidote update
  assert_success
  run git -C "$dir" rev-parse --is-shallow-repository
  assert_output "false"
}

# The clone's background deepen can still hold shallow.lock when update
# runs. That is contention, not a failed update.
@test "update tolerates a shallow.lock held by a background deepen" {
  ZSTYLES="$ZSTYLES
zstyle ':antidote:bundle:foo/baz' shallow no"
  : >"$BAZDIR/.git/shallow.lock"

  run antidote update
  assert_success
  refute_output --partial "update failed for 'foo/baz'"
  refute_output --partial "unexpected git error"
}

@test "update reports repositories with the same short name separately" {
  rollback_foo_baz
  local other="$AHOME/other.example/foo/baz"
  local bare="$(antidote_fixture_dir)/bare/https-COLON--SLASH--SLASH-fakegitsite.com-SLASH-foo-SLASH-baz.git"
  mkdir -p "$(dirname "$other")"
  cp -R "$BAZDIR" "$other"
  tgit -C "$other" remote set-url origin https://other.example/foo/baz
  tgit config --global --add url."$bare".insteadOf https://other.example/foo/baz

  run antidote update --dry-run
  assert_success
  [ "$(grep -c 'update available: foo/baz' <<<"$output")" -eq 2 ]
}

@test "update pulls a rolled-back bundle to the latest commit" {
  rollback_foo_baz
  run antidote update
  assert_output --partial "antidote: updated: foo/baz bde701c -> 98cdde2"
  run git -C "$BAZDIR" rev-parse --short HEAD
  assert_output "98cdde2"
}

@test "update reports worker failures and skips autosnapshot" {
  local snapdir="$BATS_TEST_TMPDIR/snapshots"
  tgit -C "$BAZDIR" remote set-url origin /does/not/exist/foo/baz
  ZSTYLES="$ZSTYLES
zstyle ':antidote:snapshot' dir '$snapdir'
zstyle ':antidote:snapshot:automatic' enabled yes"

  run antidote update
  assert_failure
  assert_output --partial "antidote: update failed for 'foo/baz'"
  refute_output --partial "Bundle updates complete."
  [ ! -e "$snapdir" ]
}

# The EXIT trap is the only thing that removes the worker temp dir, so a
# leftover antidote.* dir here means the trap stopped firing.
@test "update removes its temp dir" {
  local tmpbase="$BATS_TEST_TMPDIR/atmp"
  mkdir -p "$tmpbase"
  EXTRA_ENV="ANTIDOTE_TMPDIR=$tmpbase"

  run antidote update
  assert_success
  [ -z "$(ls -A "$tmpbase")" ]
}

@test "update removes its temp dir when a worker fails" {
  local tmpbase="$BATS_TEST_TMPDIR/atmp"
  mkdir -p "$tmpbase"
  tgit -C "$BAZDIR" remote set-url origin /does/not/exist/foo/baz
  EXTRA_ENV="ANTIDOTE_TMPDIR=$tmpbase"

  run antidote update
  assert_failure
  [ -z "$(ls -A "$tmpbase")" ]
}

@test "parent-shell bundle update completes" {
  fixture_session <<<'antidote update --bundles >/dev/null; echo "update exit: $?"'
  assert_output "update exit: 0"
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
  assert_output --partial "antidote: updated: foo/baz bde701c -> 98cdde2"
  run grep -c junk "$BAZDIR/baz.plugin.zsh"
  assert_output "1"
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
( use_fake_update; antidote-update --self )
EOS
  assert_success
  expect "Updating antidote...
antidote self-update complete.

antidote version $EXPECTED_VERSION"
}

# A repo with no remote makes the pull fail.
@test "self-update failure reports an error" {
  SESSION_PRELUDE="$fake_checkout_prelude"
  run_session <<'EOS'
( use_fake_update; antidote-update --self 2>&1 )
EOS
  assert_failure 1
  expect "Updating antidote...
antidote: self-update failed."
}
