#!/usr/bin/env bats
# Static file zcompile tests (ported from tests/test_zcompile_static.md).
# antidote load runs in the parent shell, so these use sessions.

load helpers/common

setup() {
  antidote_common_setup
  SESSION_PRELUDE='antidote bundle <$ZDOTDIR/.base_test_fixtures.txt &>/dev/null'
}

@test "static zcompile on compiles the static file" {
  SESSION_PRELUDE="$SESSION_PRELUDE
zstyle ':antidote:static' zcompile 'yes'
zstyle ':antidote:static' file \$ZDOTDIR/.zplugins.static.zsh"
  run_session <<'EOS'
antidote load $ZDOTDIR/.zplugins_fake_load >/dev/null
grep -q zrecompile $ZDOTDIR/.zplugins.static.zsh && echo "static file has zcompile header"
[[ -e $ZDOTDIR/.zplugins.static.zsh.zwc ]] && echo "zwc compiled"
EOS
  assert_line "static file has zcompile header"
  assert_line "zwc compiled"
}

@test "static zcompile golden output" {
  SESSION_PRELUDE="$SESSION_PRELUDE
zstyle ':antidote:static' zcompile 'yes'
zstyle ':antidote:static' file \$ZDOTDIR/.zplugins_fake_zcompile_static.zsh"
  run_session <<'EOS'
antidote load $ZDOTDIR/.zplugins_fake_load >/dev/null
cat $ZDOTDIR/.zplugins_fake_zcompile_static.zsh | subenv
EOS
  expect "$(cat "$PRJDIR/tests/testdata/.zplugins_fake_zcompile_static.zsh")"
}

# Bundling a bad repo fails; the zcompile header still prints since it
# is emitted before clone failures are detected.
@test "bad repo bundling fails with static zcompile on" {
  SESSION_PRELUDE="zstyle ':antidote:static' zcompile 'yes'"
  run_session <<<'antidote bundle does-not/exist &>/dev/null'
  assert_failure 1
}

@test "static zcompile off leaves no zwc file" {
  SESSION_PRELUDE="$SESSION_PRELUDE
zstyle ':antidote:static' zcompile 'no'
zstyle ':antidote:static' file \$ZDOTDIR/.zplugins_fake_load.zsh"
  run_session <<'EOS'
antidote load $ZDOTDIR/.zplugins_fake_load >/dev/null
[[ ! -e $ZDOTDIR/.zplugins_fake_load.zsh.zwc ]] && echo "no zwc file"
EOS
  assert_output "no zwc file"
}
