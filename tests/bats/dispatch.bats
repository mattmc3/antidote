#!/usr/bin/env bats
# antidote dispatch tests (ported from tests/test_cmd_dispatch.md).
# Dispatch is core to everything, so we don't need to test much here.

load helpers/common

setup() { antidote_common_setup; }

# Lazy-loading antidote must work from either the repo root or the
# functions dir. Fix #54. $dir expands in bats; session vars escaped.
lazy_load_check() {
  local dir=$1
  run_session <<EOS
t_unload_antidote
echo "dispatch loaded: \$+functions[antidote-dispatch]"
autoload -Uz $dir/antidote
antidote -v &>/dev/null && echo "antidote -v works"
echo "dispatch loaded: \$+functions[antidote-dispatch]"
EOS
  assert_line --index 0 "dispatch loaded: 0"
  assert_line --index 1 "antidote -v works"
  assert_line --index 2 "dispatch loaded: 1"
}

@test "antidote-dispatch --version works" {
  run_session <<<'antidote-dispatch --version >/dev/null && echo "dispatch --version ok"'
  assert_output "dispatch --version ok"
}

@test "antidote lazy loads from the repo root" {
  lazy_load_check '$T_PRJDIR'
}

@test "antidote lazy loads from the functions dir" {
  lazy_load_check '$T_PRJDIR/functions'
}

# A copy of antidote.zsh outside a git checkout has no sha to show and
# must not print errors trying to find one.
@test "version works outside a git repo with no errors" {
  antidote_test_home
  cp "$PRJDIR/antidote.zsh" "$BATS_TEST_TMPDIR/antidote.zsh"
  run env HOME="$TESTHOME" zsh "$BATS_TEST_TMPDIR/antidote.zsh" --version
  assert_success
  assert_output "antidote version $EXPECTED_VERSION"
}
