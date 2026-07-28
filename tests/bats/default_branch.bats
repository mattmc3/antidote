#!/usr/bin/env bats
# Bundles whose remote default branch is not main.
#
# The devhead/devrepo fixture has main and dev, diverged, with the bare
# repo's HEAD on dev. Following the wrong branch is therefore visible in
# the plugin file, which main and dev end differently.

load helpers/common

setup() {
  antidote_common_setup
  antidote_test_home
  ZSTYLES="zstyle ':antidote:test:version' show-sha off
zstyle ':antidote:test:git' autostash off"
  DEVDIR="$AHOME/fakegitsite.com/devhead/devrepo"
}

@test "a clone follows the remote default branch" {
  run antidote bundle 'devhead/devrepo kind:clone'
  assert_success
  run git -C "$DEVDIR" rev-parse --abbrev-ref HEAD
  assert_output "dev"
  run tail -1 "$DEVDIR/devrepo.plugin.zsh"
  assert_output "# on dev"
}

@test "a branch annotation still wins over the default branch" {
  run antidote bundle 'devhead/devrepo kind:clone branch:main'
  assert_success
  run git -C "$DEVDIR" rev-parse --abbrev-ref HEAD
  assert_output "main"
  run tail -1 "$DEVDIR/devrepo.plugin.zsh"
  assert_output "# on main"
}

@test "update keeps a default-branch clone on that branch" {
  run antidote bundle 'devhead/devrepo kind:clone'
  assert_success
  tgit_deepen "$DEVDIR"
  tgit -C "$DEVDIR" reset --quiet --hard HEAD~1

  run antidote update
  assert_success
  refute_output --partial "update failed for 'devhead/devrepo'"
  run git -C "$DEVDIR" rev-parse --abbrev-ref HEAD
  assert_output "dev"
  run git -C "$DEVDIR" rev-parse HEAD
  assert_output "$(git -C "$DEVDIR" rev-parse refs/remotes/origin/dev)"
}

# Detached with no upstream, so git_upstream_ref falls back. The fallback
# has to land on dev, not on main.
@test "update follows origin HEAD from a detached clone" {
  run antidote bundle "devhead/devrepo kind:clone"
  assert_success
  tgit_deepen "$DEVDIR"
  tgit -C "$DEVDIR" checkout --quiet --detach HEAD~1

  run antidote update
  assert_success
  run git -C "$DEVDIR" rev-parse HEAD
  assert_output "$(git -C "$DEVDIR" rev-parse refs/remotes/origin/dev)"
}
