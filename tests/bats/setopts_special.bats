#!/usr/bin/env bats
# antidote handles special Zsh options (ported from
# tests/test_setopts_special.md). See issue #154.

load helpers/common

setup() {
  antidote_common_setup
  SESSION_PRELUDE='antidote bundle <$ZDOTDIR/.base_test_fixtures.txt &>/dev/null
setopt KSH_ARRAYS SH_GLOB'
}

@test "bundle output is unaffected by KSH_ARRAYS and SH_GLOB" {
  run_session <<'EOS'
antidote bundle <$ZDOTDIR/.zsh_plugins.txt | subenv
EOS
  expect "$(cat "$PRJDIR/tests/testdata/.zsh_plugins.zsh")"
}

@test "dispatch preserves KSH_ARRAYS and SH_GLOB" {
  run_session <<'EOS'
antidote bundle foo/bar >/dev/null
echo "ksh_arrays=${options[ksharrays]} sh_glob=${options[shglob]}"
unsetopt KSH_ARRAYS SH_GLOB
antidote bundle foo/bar >/dev/null
echo "ksh_arrays=${options[ksharrays]} sh_glob=${options[shglob]}"
EOS
  assert_line --index 0 "ksh_arrays=on sh_glob=on"
  assert_line --index 1 "ksh_arrays=off sh_glob=off"
}
