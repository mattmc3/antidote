#!/usr/bin/env bats
# antidote.zsh as a lone file, with no functions/ dir beside it.
# Commands the subprocess can answer on its own must still work; load
# and dynamic mode need parent-shell functions and cannot.

load lib/bats-support/load
load lib/bats-assert/load

setup() {
  PRJDIR="$BATS_TEST_DIRNAME/../.."
  SOLO="$BATS_TEST_TMPDIR/solo"
  mkdir -p "$SOLO" "$BATS_TEST_TMPDIR/home"
  cp "$PRJDIR/antidote.zsh" "$SOLO/antidote.zsh"
  SOLOHOME="$(cd "$BATS_TEST_TMPDIR/home" && pwd -P)"
}

# Source the lone copy in a bare shell, then run the given zsh code.
solo() {
  run env -i HOME="$SOLOHOME" PATH="$PATH" zsh -fc \
    "source $SOLO/antidote.zsh || exit 9
$1"
}

@test "sourcing a lone antidote.zsh defines the antidote function" {
  solo 'print "antidote: $+functions[antidote]"'
  assert_success
  assert_output "antidote: 1"
}

@test "sourcing a lone antidote.zsh is quiet" {
  solo ':'
  assert_success
  assert_output ""
}

# Compared against the same lone file run directly, so the assert holds
# on any OS branch.
@test "a lone antidote.zsh answers subprocess-backed commands" {
  local direct
  direct=$(env -i HOME="$SOLOHOME" PATH="$PATH" zsh "$SOLO/antidote.zsh" home)
  [ -n "$direct" ]
  solo 'antidote home'
  assert_success
  assert_output "$direct"
}

@test "a lone antidote.zsh reports its version" {
  solo 'antidote --version'
  assert_success
  assert_output --partial "antidote version"
}

@test "a lone antidote.zsh emits the dynamic-mode function" {
  solo 'antidote init | tail -n1'
  assert_success
  assert_output "}"
}

# ANTIDOTE_ZSH points at the sourced file, so the shim finds itself even
# after a cd.
@test "a lone antidote.zsh works from another directory" {
  local direct
  direct=$(env -i HOME="$SOLOHOME" PATH="$PATH" zsh "$SOLO/antidote.zsh" home)
  solo 'cd /; antidote home'
  assert_success
  assert_output "$direct"
}

# The functions dir wins when it is present; the shim is a fallback only.
@test "the functions dir still takes precedence when present" {
  run env -i HOME="$SOLOHOME" PATH="$PATH" zsh -fc \
    "source $PRJDIR/antidote.zsh || exit 9
print \"load: \$+functions[antidote-load]\""
  assert_success
  assert_output "load: 1"
}
