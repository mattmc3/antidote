#!/usr/bin/env bats
# antidote dispatch tests.
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

# The antidote function autoloads from fpath and resolves on first call.
@test "antidote autoloads lazily from fpath" {
  run env HOME="$BATS_TEST_TMPDIR" ANTIDOTE_CONFIG=/dev/null \
    ANTIDOTE_ZSTYLES="zstyle ':antidote:test:version' show-sha off" \
    zsh -f -c '
      print "defined before autoload: $+functions[antidote]"
      fpath=($PWD $fpath)
      autoload -Uz antidote
      print "defined after autoload: $+functions[antidote]"
      whence -f antidote | grep -o "builtin autoload -XUz"
      antidote -h | head -n1
    '
  assert_success
  assert_line --index 0 'defined before autoload: 0'
  assert_line --index 1 'defined after autoload: 1'
  assert_line --index 2 "builtin autoload -XUz"
  assert_line --index 3 "antidote - the cure to slow zsh plugin management"
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
