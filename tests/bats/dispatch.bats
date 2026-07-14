#!/usr/bin/env bats
# antidote dispatch tests (ported from tests/test_cmd_dispatch.md).
# Dispatch is core to everything, so we don't need to test much here.

load helpers/common

setup() { antidote_common_setup; }

@test "antidote-dispatch --version works" {
  run_session <<'EOS'
antidote-dispatch --version >/dev/null && echo "dispatch --version ok"
EOS
  expect "dispatch --version ok"
}

# Lazy-loading antidote must work from either the repo root or the
# functions dir. Fix #54.
@test "antidote lazy loads from repo root and functions dir" {
  run_session <<'EOS'
loaded() { echo "dispatch loaded: $+functions[antidote-dispatch]" }
loaded
t_unload_antidote; loaded
autoload -Uz $T_PRJDIR/antidote
antidote -v &>/dev/null && echo "repo root: antidote -v works"
loaded
t_unload_antidote; loaded
autoload -Uz $T_PRJDIR/functions/antidote
antidote -v &>/dev/null && echo "functions dir: antidote -v works"
loaded
EOS
  expect "dispatch loaded: 1
dispatch loaded: 0
repo root: antidote -v works
dispatch loaded: 1
dispatch loaded: 0
functions dir: antidote -v works
dispatch loaded: 1"
}

# A copy of antidote.zsh outside a git checkout has no sha to show and
# must not print errors trying to find one.
@test "version works outside a git repo with no errors" {
  antidote_test_home
  cp "$PRJDIR/antidote.zsh" "$BATS_TEST_TMPDIR/antidote.zsh"
  run env HOME="$TESTHOME" zsh "$BATS_TEST_TMPDIR/antidote.zsh" --version
  [ "$status" -eq 0 ]
  expect "antidote version $EXPECTED_VERSION"
}
