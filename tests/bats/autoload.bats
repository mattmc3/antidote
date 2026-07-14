#!/usr/bin/env bats
# Lazy-load test (ported from tests/test_autoload.md): the antidote
# function autoloads from fpath and resolves on first call.

load helpers/common

setup() {
  cd "$BATS_TEST_DIRNAME/../.."
}

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
