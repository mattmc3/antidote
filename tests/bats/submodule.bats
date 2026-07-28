#!/usr/bin/env bats
# Bundles that carry a git submodule.
#
# The sub/parent fixture records sub/child as a submodule, so cloning it
# exercises git_clone's --recurse-submodules and updating it exercises
# git_submodule_sync and git_submodule_update.

load helpers/common

setup() {
  antidote_common_setup
  antidote_test_home
  ZSTYLES="zstyle ':antidote:test:version' show-sha off
zstyle ':antidote:test:git' autostash off"
  PARENTDIR="$AHOME/fakegitsite.com/sub/parent"
}

@test "a clone checks out its submodules" {
  run antidote bundle 'sub/parent kind:clone'
  assert_success
  [ -f "$PARENTDIR/child/child.plugin.zsh" ]
}

@test "a submodule is cloned shallow" {
  run antidote bundle 'sub/parent kind:clone'
  assert_success
  run git -C "$PARENTDIR/child" rev-parse --is-shallow-repository
  assert_output "true"
}

# Cloning must not put git's own chatter on stdout, which is the script.
@test "cloning a submodule emits only the load script" {
  run antidote bundle sub/parent
  subenv_output ANTIDOTE_HOME
  expect '# antidote cloning sub/parent...
fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/sub/parent" )
source "$ANTIDOTE_HOME/fakegitsite.com/sub/parent/parent.plugin.zsh"'
}

@test "update leaves a submodule checked out" {
  run antidote bundle 'sub/parent kind:clone'
  assert_success

  run antidote update
  assert_success
  refute_output --partial "update failed for 'sub/parent'"
  [ -f "$PARENTDIR/child/child.plugin.zsh" ]
}

@test "update restores an emptied submodule" {
  run antidote bundle 'sub/parent kind:clone'
  assert_success
  rm -rf "$PARENTDIR/child"
  mkdir -p "$PARENTDIR/child"

  run antidote update
  assert_success
  [ -f "$PARENTDIR/child/child.plugin.zsh" ]
}

# The shallow-graft path resets instead of rebasing, so make sure the
# submodule comes back from that too.
@test "a shallow graft reset leaves a submodule checked out" {
  ZSTYLES="$ZSTYLES
zstyle ':antidote:bundle:sub/parent' shallow yes"
  run antidote bundle 'sub/parent kind:clone'
  assert_success
  tgit_deepen "$PARENTDIR"
  tgit -C "$PARENTDIR" reset --quiet --hard HEAD~1
  tgit -C "$PARENTDIR" rev-parse HEAD refs/remotes/origin/main >"$PARENTDIR/.git/shallow"

  run antidote update
  assert_success
  refute_output --partial "update failed for 'sub/parent'"
  [ -f "$PARENTDIR/child/child.plugin.zsh" ]
}
