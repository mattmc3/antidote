#!/usr/bin/env bats
# Symlinked ANTIDOTE_HOME tests (ported from
# tests/test_symlinked_antidote_home.md)

load helpers/common

setup() {
  antidote_common_setup
  antidote_test_home
  ZSTYLES="zstyle ':antidote:test:version' show-sha off
zstyle ':antidote:test:git' autostash off"
  # Point ANTIDOTE_HOME (the wrapper's AHOME) at a symlinked directory.
  REAL_HOME="$TESTHOME/.cache/antidote-real"
  mkdir -p "$REAL_HOME"
  ln -s "$REAL_HOME" "$TESTHOME/.cache/antidote-link"
  AHOME="$TESTHOME/.cache/antidote-link"
}

@test "home reports the symlink path" {
  run antidote home
  assert_output "$AHOME"
}

@test "list warns for an empty symlinked home" {
  run antidote list
  expect "antidote: list: no bundles found in '\$HOME/.cache/antidote-link'"
}

@test "bundle clones through the symlink into the real dir" {
  run antidote bundle foo/bar
  assert_success
  [ -d "$REAL_HOME/fakegitsite.com/foo/bar/.git" ]
}

@test "list finds bundles through the symlink" {
  antidote bundle foo/bar &>/dev/null
  antidote bundle pintest/pinme &>/dev/null
  run antidote list --dirs
  expect "$AHOME/fakegitsite.com/foo/bar
$AHOME/fakegitsite.com/pintest/pinme"
  run antidote list --url
  expect "https://fakegitsite.com/foo/bar
https://fakegitsite.com/pintest/pinme"
}

@test "list --long and --jsonl work through the symlink" {
  antidote bundle foo/bar &>/dev/null
  run antidote list --long
  assert_output --partial "Path:   \$HOME/.cache/antidote-link/fakegitsite.com/foo/bar"
  run antidote list --jsonl
  assert_output --partial "\"path\":\"$AHOME/fakegitsite.com/foo/bar\""
}

@test "path resolves bundles through the symlink" {
  antidote bundle foo/bar &>/dev/null
  run antidote path foo/bar
  assert_output "$AHOME/fakegitsite.com/foo/bar"
}

@test "pinned bundles are skipped by update through the symlink" {
  antidote bundle "pintest/pinme pin:$PIN_V100" &>/dev/null
  run antidote update -n
  assert_output --partial "skipping update for pinned bundle: pintest/pinme"
  run git -C "$AHOME/fakegitsite.com/pintest/pinme" rev-parse HEAD
  assert_output "$PIN_V100"
}

@test "unpinned bundles update through the symlink" {
  antidote bundle "pintest/pinme pin:$PIN_V100" &>/dev/null
  antidote bundle 'pintest/pinme' >/dev/null
  antidote update &>/dev/null
  run git -C "$AHOME/fakegitsite.com/pintest/pinme" rev-parse HEAD
  assert_output "$PIN_V120"
}

# Snapshot save enumerates bundles via find_bundles, which scans
# ANTIDOTE_HOME.
@test "snapshot save works through the symlink" {
  antidote bundle foo/bar &>/dev/null
  run antidote snapshot save
  assert_output --partial "Snapshot saved:"
  run antidote snapshot list
  [[ "$output" == *snapshot-*.txt ]]
}

@test "purge removes a bundle from the symlink target" {
  antidote bundle foo/bar &>/dev/null
  run antidote purge foo/bar
  assert_output --partial "Removed 'foo/bar'."
  [ ! -d "$REAL_HOME/fakegitsite.com/foo/bar" ]
}

@test "purge --all empties the real dir and removes the symlink" {
  antidote bundle foo/bar &>/dev/null
  ZSTYLES="$ZSTYLES
zstyle ':antidote:test:purge' answer 'y'"
  run antidote purge --all
  assert_output --partial "Antidote purge complete."
  [ ! -e "$AHOME" ]
  [ -d "$REAL_HOME" ]
  run find "$REAL_HOME" -mindepth 1
  refute_output
}

# Documents current behavior when the symlink target is outside $HOME:
# purge still removes bundle contents via the symlink path.
@test "purge works when the symlink target is outside HOME" {
  REAL_EXT="$BATS_TEST_TMPDIR/antidote-ext"
  mkdir -p "$REAL_EXT"
  ln -s "$REAL_EXT" "$TESTHOME/.cache/antidote-link-external"
  AHOME="$TESTHOME/.cache/antidote-link-external"
  EXTRA_ENV="ANTIDOTE_TMPDIR=$BATS_TEST_TMPDIR"
  antidote bundle foo/bar &>/dev/null
  run antidote purge foo/bar
  assert_output --partial "Removed 'foo/bar'."
  [ ! -d "$REAL_EXT/fakegitsite.com/foo/bar" ]
}
