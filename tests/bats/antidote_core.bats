#!/usr/bin/env bats
# antidote core tests.
# Tests for antidote's most basic functionality.

load helpers/common

setup() { antidote_common_setup; }

@test "fails gracefully when someone tries bash" {
  run_session <<<'bash -c "source $T_PRJDIR/antidote.zsh"'
  assert_output "antidote: This script requires Zsh, not Bash"
}

@test "no args displays help and exits 2" {
  run_session <<'EOS'
echo "antidote fn defined: $+functions[antidote]"
antidote
EOS
  assert_failure 2
  assert_line --index 0 "antidote fn defined: 1"
  assert_output --partial "$(cat "$PRJDIR/tests/testdata/usage_dispatch.txt")"
}

@test "help and version flags work" {
  run_session <<'EOS'
antidote -h >/dev/null; echo "-h exit: $?"
antidote --help >/dev/null; echo "--help exit: $?"
antidote -v >/dev/null; echo "-v exit: $?"
antidote --version
EOS
  assert_line "-h exit: 0"
  assert_line "--help exit: 0"
  assert_line "-v exit: 0"
  assert_line --regexp '^antidote version [0-9]+\.[0-9]+\.[0-9]+ \([a-f0-9]+\)$'
}

@test "diagnostics shows system info" {
  run_session <<<'antidote --diagnostics; echo "exit: $?"'
  assert_line --index 0 "antidote:"
  assert_line --regexp '^[[:space:]]+version:[[:space:]]+[0-9]+\.[0-9]+\.[0-9]+'
  assert_line --regexp '^[[:space:]]+snapshot dir:[[:space:]]+.+'
  assert_line --regexp '^[[:space:]]+snapshots:[[:space:]]+[0-9]+'
  assert_line --regexp '^[[:space:]]+zsh version:[[:space:]]+.+'
  assert_line --regexp '^[[:space:]]+git version:[[:space:]]+.+'
  assert_line --regexp '^[[:space:]]+system:[[:space:]]+.+'
  assert_line "exit: 0"
}

@test "unrecognized options and commands fail with exit 1" {
  run_session <<'EOS'
antidote --foo 2>&1 >/dev/null; echo "bad option exit: $?"
antidote foo 2>&1; echo "bad command exit: $?"
EOS
  assert_line --regexp 'bad option|command not found'
  assert_line "bad option exit: 1"
  assert_line "antidote: command not found 'foo'"
  assert_line "bad command exit: 1"
}
