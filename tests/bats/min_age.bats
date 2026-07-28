#!/usr/bin/env bats
# antidote min-age tests
#
# The dino/saur fixture has three commits, dated relative to fixture
# generation: initial (~900 days), stable (~400 days), and latest
# (~1 day). A min-age of 200 always qualifies stable but never latest.

load helpers/common

setup() {
  antidote_common_setup
  antidote_test_home
  ZSTYLES="zstyle ':antidote:test:version' show-sha off
zstyle ':antidote:test:git' autostash off"
  SAURDIR="$AHOME/fakegitsite.com/dino/saur"
}

# Newest commit at least $1 days old, per the remote's branch.
qualifying_sha() {
  tgit -C "$SAURDIR" rev-list --before="$1 days ago" -1 origin/main
}

@test "clone with min-age lands on the newest commit old enough" {
  ZSTYLES+="
zstyle ':antidote:bundle:dino/saur' min-age 200"
  run antidote bundle 'dino/saur kind:clone'
  assert_success
  run git -C "$SAURDIR" rev-parse HEAD
  assert_output "$(qualifying_sha 200)"
  refute_output "$(git -C "$SAURDIR" rev-parse origin/main)"
}

@test "clone without min-age lands on the latest commit" {
  run antidote bundle 'dino/saur kind:clone'
  assert_success
  run git -C "$SAURDIR" rev-parse HEAD
  assert_output "$(git -C "$SAURDIR" rev-parse origin/main)"
}

# A brand new plugin has nothing old enough to qualify. Install it at
# the latest commit rather than refusing to clone it.
@test "clone keeps the latest commit when nothing is old enough" {
  ZSTYLES+="
zstyle ':antidote:bundle:dino/saur' min-age 5000"
  run antidote bundle 'dino/saur kind:clone'
  assert_success
  assert_output --partial "# antidote: dino/saur: no commits older than 5000 days, using latest"
  run git -C "$SAURDIR" rev-parse HEAD
  assert_output "$(git -C "$SAURDIR" rev-parse origin/main)"
}

@test "update advances only as far as min-age allows" {
  run antidote bundle 'dino/saur kind:clone'
  assert_success
  tgit_deepen "$SAURDIR"
  local stable
  stable=$(qualifying_sha 200)
  tgit -C "$SAURDIR" reset --quiet --hard "$(git -C "$SAURDIR" rev-list --max-parents=0 HEAD)"
  ZSTYLES+="
zstyle ':antidote:bundle:dino/saur' min-age 200"
  run antidote update
  assert_success
  run git -C "$SAURDIR" rev-parse HEAD
  assert_output "$stable"
}

@test "update skips a bundle when no commit is old enough" {
  run antidote bundle 'dino/saur kind:clone'
  assert_success
  local before
  before=$(git -C "$SAURDIR" rev-parse HEAD)
  ZSTYLES+="
zstyle ':antidote:bundle:dino/saur' min-age 5000"
  run antidote update
  assert_success
  assert_output --partial "antidote: dino/saur: no commits older than 5000 days, skipping update"
  run git -C "$SAURDIR" rev-parse HEAD
  assert_output "$before"
}

@test "dry run reports the min-age commit without moving HEAD" {
  ZSTYLES+="
zstyle ':antidote:bundle:dino/saur' min-age 200"
  run antidote bundle 'dino/saur kind:clone'
  assert_success
  # the min-age clone already unshallowed, so the history is here
  local stable before
  stable=$(qualifying_sha 200)
  tgit -C "$SAURDIR" reset --quiet --hard "$(git -C "$SAURDIR" rev-list --max-parents=0 HEAD)"
  before=$(git -C "$SAURDIR" rev-parse HEAD)
  run antidote update --dry-run
  assert_output --partial "antidote: update available: dino/saur ${before:0:7} -> ${stable:0:7}"
  run git -C "$SAURDIR" rev-parse HEAD
  assert_output "$before"
}

# A pin fixes the commit outright, so min-age has nothing to decide.
@test "a pinned bundle ignores min-age" {
  local latest
  run antidote bundle 'dino/saur kind:clone'
  assert_success
  latest=$(git -C "$SAURDIR" rev-parse origin/main)
  rm -rf "$SAURDIR"
  ZSTYLES+="
zstyle ':antidote:bundle:dino/saur' min-age 200"
  run antidote bundle "dino/saur kind:clone pin:$latest"
  assert_success
  run git -C "$SAURDIR" rev-parse HEAD
  assert_output "$latest"
}

# A branch: clone still gets held back, measured on that branch's tip.
@test "min-age applies to a branch clone" {
  ZSTYLES+="
zstyle ':antidote:bundle:dino/saur' min-age 200"
  run antidote bundle 'dino/saur kind:clone branch:main'
  assert_success
  run git -C "$SAURDIR" rev-parse HEAD
  assert_output "$(qualifying_sha 200)"
}

# min-age only moves a bundle at clone time. An existing clone stays put
# until the next update, which is where the age cap gets enforced.
@test "adding min-age later does not rewind an existing clone" {
  run antidote bundle 'dino/saur kind:clone'
  assert_success
  local latest
  latest=$(git -C "$SAURDIR" rev-parse HEAD)
  ZSTYLES+="
zstyle ':antidote:bundle:dino/saur' min-age 200"
  run antidote bundle 'dino/saur kind:clone'
  assert_success
  run git -C "$SAURDIR" rev-parse HEAD
  assert_output "$latest"
}

# min-age has to search history for a commit old enough, so it wins over
# a shallow hold and deepens the clone anyway.
@test "min-age deepens a bundle held shallow" {
  ZSTYLES+="
zstyle ':antidote:bundle:dino/saur' min-age 200
zstyle ':antidote:bundle:dino/saur' shallow yes"
  run antidote bundle 'dino/saur kind:clone'
  assert_success
  run git -C "$SAURDIR" rev-parse --is-shallow-repository
  assert_output "false"
  run git -C "$SAURDIR" rev-parse HEAD
  assert_output "$(qualifying_sha 200)"
}

@test "min-age 0 opts a bundle out of a pattern style" {
  ZSTYLES+="
zstyle ':antidote:bundle:*' min-age 200
zstyle ':antidote:bundle:dino/saur' min-age 0"
  run antidote bundle 'dino/saur kind:clone'
  assert_success
  run git -C "$SAURDIR" rev-parse HEAD
  assert_output "$(git -C "$SAURDIR" rev-parse origin/main)"
}

# Fail-safe: an empty value must not error out mid-clone.
@test "an empty min-age is treated as no delay" {
  ZSTYLES+="
zstyle ':antidote:bundle:dino/saur' min-age ''"
  run antidote bundle 'dino/saur kind:clone'
  assert_success
  run git -C "$SAURDIR" rev-parse HEAD
  assert_output "$(git -C "$SAURDIR" rev-parse origin/main)"
}

@test "a min-age that is not a whole number of days is an error" {
  ZSTYLES+="
zstyle ':antidote:bundle:dino/saur' min-age soon"
  run antidote bundle 'dino/saur kind:clone'
  assert_failure
  assert_output --partial "antidote: error: min-age requires a whole number of days, got 'soon'"
  refute [ -d "$SAURDIR" ]
}

# Update aggregates per-worker status, so a bad value fails the command
# as well as reporting, and still leaves the bundle alone.
@test "a bad min-age during update fails without touching the bundle" {
  run antidote bundle 'dino/saur kind:clone'
  assert_success
  local before
  before=$(git -C "$SAURDIR" rev-parse HEAD)
  ZSTYLES+="
zstyle ':antidote:bundle:dino/saur' min-age soon"
  run antidote update
  assert_failure
  assert_output --partial "antidote: error: min-age requires a whole number of days, got 'soon'"
  run git -C "$SAURDIR" rev-parse HEAD
  assert_output "$before"
}

@test "a negative min-age is an error" {
  ZSTYLES+="
zstyle ':antidote:bundle:dino/saur' min-age -30"
  run antidote bundle 'dino/saur kind:clone'
  assert_failure
  assert_output --partial "antidote: error: min-age requires a whole number of days, got '-30'"
}
