#!/usr/bin/env bats
# Lazy-load test (ported from tests/test_autoload.md): the antidote
# function autoloads from fpath and resolves on first call.

setup() {
  cd "$BATS_TEST_DIRNAME/../.."
}

@test "antidote autoloads lazily from fpath" {
  run env HOME="$BATS_TEST_TMPDIR" ANTIDOTE_CONFIG=/dev/null \
    ANTIDOTE_ZSTYLES="zstyle ':antidote:test:version' show-sha off" \
    zsh -f -c '
      print $+functions[antidote]
      fpath=($PWD $fpath)
      autoload -Uz antidote
      print $+functions[antidote]
      whence -f antidote | grep -o "builtin autoload -XUz"
      antidote -h | head -n1
    '
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "0" ]
  [ "${lines[1]}" = "1" ]
  [ "${lines[2]}" = "builtin autoload -XUz" ]
  [ "${lines[3]}" = "antidote - the cure to slow zsh plugin management" ]
}
