#!/usr/bin/env bats
# antidote pin annotation tests (ported from tests/test_pin.md).
#
# The pintest/pinme fixture has three commits:
# - v1.0.0 - initial good version
# - v1.1.0 - minor update, also good
# - v1.2.0 - bad supply chain commit (HEAD)
# Pinning lets users lock to a known-good commit and avoid the bad HEAD.

load helpers/common

setup() {
  antidote_common_setup
  antidote_test_home
  ZSTYLES="zstyle ':antidote:test:version' show-sha off
zstyle ':antidote:test:git' autostash off"
  PINDIR="$AHOME/fakegitsite.com/pintest/pinme"
}

check_critical() {
  printf '%s\n' "$@" | antidote __private__ bundle_check_critical 2>&1
}

@test "clone with pin checks out the pinned SHA detached" {
  antidote bundle "pintest/pinme pin:$PIN_V100" >/dev/null
  run git -C "$PINDIR" rev-parse HEAD
  assert_output "$PIN_V100"
  run git -C "$PINDIR" rev-parse --abbrev-ref HEAD
  assert_output "HEAD"
}

@test "clone with pin records the pin in git config" {
  antidote bundle "pintest/pinme pin:$PIN_V100" >/dev/null
  run git -C "$PINDIR" config --get antidote.pin
  assert_output "$PIN_V100"
}

# Output paths print with a literal '$HOME' prefix (print_path).
@test "pinned bundle generates the normal source script" {
  antidote bundle "pintest/pinme pin:$PIN_V100" &>/dev/null
  run antidote __private__ zsh_script __bundle__ pintest/pinme pin "$PIN_V100"
  expect 'fpath+=( "$HOME/.cache/antidote/fakegitsite.com/pintest/pinme" )
source "$HOME/.cache/antidote/fakegitsite.com/pintest/pinme/pinme.plugin.zsh"'
}

@test "update skips pinned bundles" {
  antidote bundle "pintest/pinme pin:$PIN_V100" >/dev/null
  run antidote update -n
  assert_output --partial "skipping update for pinned bundle: pintest/pinme (at 64642c5...)"
}

@test "re-bundling with a new pin advances the checkout" {
  antidote bundle "pintest/pinme pin:$PIN_V100" >/dev/null
  antidote bundle "pintest/pinme pin:$PIN_V110" >/dev/null
  run git -C "$PINDIR" rev-parse HEAD
  assert_output "$PIN_V110"
  run git -C "$PINDIR" config --get antidote.pin
  assert_output "$PIN_V110"
}

@test "removing the pin clears git config and returns to a branch" {
  antidote bundle "pintest/pinme pin:$PIN_V110" >/dev/null
  antidote bundle 'pintest/pinme' >/dev/null
  run git -C "$PINDIR" config --get antidote.pin
  assert_failure 1
  run git -C "$PINDIR" rev-parse --abbrev-ref HEAD
  assert_output "main"
}

@test "after unpinning, update pulls to the latest commit" {
  antidote bundle "pintest/pinme pin:$PIN_V110" >/dev/null
  antidote bundle 'pintest/pinme' >/dev/null
  antidote update &>/dev/null
  run git -C "$PINDIR" rev-parse HEAD
  assert_output "$PIN_V120"
}

@test "re-adding a pin re-checks out and records it" {
  antidote bundle 'pintest/pinme' >/dev/null
  antidote bundle "pintest/pinme pin:$PIN_V100" >/dev/null
  run git -C "$PINDIR" config --get antidote.pin
  assert_output "$PIN_V100"
  run git -C "$PINDIR" rev-parse --abbrev-ref HEAD
  assert_output "HEAD"
}

# Short SHAs are rejected because the git protocol cannot resolve them
# on remotes.
@test "short SHA is rejected" {
  run antidote bundle 'pintest/pinme pin:64642c5'
  assert_failure
  assert_output --partial "pin requires a full 40-character commit SHA, got '64642c5'"
}

@test "list --long shows the pin" {
  antidote bundle "pintest/pinme pin:$PIN_V110" &>/dev/null
  run antidote list --long
  assert_output --partial "Pinned: $PIN_V110"
}

@test "list --jsonl includes the pin field" {
  antidote bundle "pintest/pinme pin:$PIN_V110" &>/dev/null
  run antidote list --jsonl
  assert_output --partial "\"pin\":\"$PIN_V110\""
}

@test "kind:clone pins move forward and backward" {
  antidote bundle "pintest/pinme kind:clone pin:$PIN_V100" &>/dev/null
  antidote bundle "pintest/pinme kind:clone pin:$PIN_V120" >/dev/null
  run git -C "$PINDIR" rev-parse HEAD
  assert_output "$PIN_V120"
  antidote bundle "pintest/pinme kind:clone pin:$PIN_V100" >/dev/null
  run git -C "$PINDIR" rev-parse HEAD
  assert_output "$PIN_V100"
}

# Tags work with branch: the same as branch names.
@test "branch annotation accepts a tag" {
  antidote bundle 'pintest/pinme branch:v1.0.0' &>/dev/null
  run git -C "$PINDIR" rev-parse HEAD
  assert_output "$PIN_V100"
}

@test "pin with an unknown SHA fails and cleans up the clone" {
  run antidote __private__ zsh_script __bundle__ pintest/pinme kind clone pin deadbeefdeadbeefdeadbeefdeadbeefdeadbeef
  assert_failure
  assert_output --partial "pin commit 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeef' not found for pintest/pinme"
  [ ! -d "$PINDIR" ]
}

@test "pin with a non-SHA value is rejected without cloning" {
  run antidote __private__ zsh_script __bundle__ pintest/pinme kind clone pin v99.0.0
  assert_failure
  assert_output --partial "pin requires a full 40-character commit SHA, got 'v99.0.0'"
  [ ! -d "$PINDIR" ]
}

@test "conflicting pins are a critical error" {
  run check_critical 'pintest/pinme pin:aaa' 'pintest/pinme pin:bbb'
  assert_failure
  assert_output "# antidote: critical error on line 2: conflicting pin for 'pintest/pinme': pin:bbb vs pin:aaa"
}

@test "conflicting branches are a critical error" {
  run check_critical 'foo/bar branch:main' 'foo/bar branch:dev'
  assert_failure
  assert_output "# antidote: critical error on line 2: conflicting branch for 'foo/bar': branch:dev vs branch:main"
}

@test "mixed pin/no-pin for the same repo is a critical error" {
  run check_critical 'pintest/pinme pin:aaa' 'pintest/pinme path:lib'
  assert_failure
  assert_output "# antidote: critical error on line 2: inconsistent pin for 'pintest/pinme': some entries have pin:aaa, others do not"
}

@test "mixed branch/no-branch for the same repo is a critical error" {
  run check_critical 'foo/bar branch:dev' 'foo/bar path:lib'
  assert_failure
  assert_output "# antidote: critical error on line 2: inconsistent branch for 'foo/bar': some entries have branch:dev, others do not"
}

@test "identical pins and unrelated pins are fine" {
  run check_critical 'pintest/pinme pin:aaa' 'pintest/pinme pin:aaa path:lib'
  assert_success
  run check_critical 'foo/bar pin:aaa' 'pintest/pinme pin:bbb'
  assert_success
}

@test "bundling with conflicting pins fails end-to-end" {
  run antidote bundle "pintest/pinme pin:aaa path:lib
pintest/pinme pin:bbb path:other"
  assert_failure
  assert_output --partial "conflicting pin for 'pintest/pinme': pin:bbb vs pin:aaa"
}
