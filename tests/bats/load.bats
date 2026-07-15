#!/usr/bin/env bats
# antidote load tests (ported from tests/test_cmd_load.md). load runs in
# the parent shell (functions/antidote-load), so these use sessions.

load helpers/common

setup() { antidote_common_setup; }

@test "load sources every bundle in the plugins file" {
  fixture_session <<<'antidote load $ZDOTDIR/.zplugins_fake_load'
  expected=$(cat <<'EOF'
sourcing bar.plugin.zsh from foo/bar...
sourcing qux.plugin.zsh from foo/qux...
sourcing bar.plugin.zsh from foo/bar...
sourcing lib/lib1.zsh from ohmy/ohmy...
sourcing lib/lib2.zsh from ohmy/ohmy...
sourcing lib/lib3.zsh from ohmy/ohmy...
sourcing plugins/extract/extract.plugin.zsh from ohmy/ohmy...
sourcing plugins/docker/docker.plugin.zsh from ohmy/ohmy...
sourcing plugins/docker/docker.plugin.zsh from ohmy/ohmy...
sourcing zsh-defer.plugin.zsh from getantidote/zsh-defer...
sourcing plugins/magic-enter/magic-enter.plugin.zsh from ohmy/ohmy...
sourcing custom/themes/pretty.zsh-theme from ohmy/ohmy...
EOF
)
  expect "$expected"
}

@test "load writes the golden static file" {
  fixture_session <<'EOS'
antidote load $ZDOTDIR/.zplugins_fake_load >/dev/null
cat $ZDOTDIR/.zplugins_fake_load.zsh | subenv
EOS
  expect "$(cat "$PRJDIR/tests/testdata/.zplugins_fake_load.zsh")"
}

@test "load fails when bundle and static file are the same" {
  SESSION_PRELUDE="cp \$ZDOTDIR/.zplugins_fake_load \$ZDOTDIR/.zplugins.txt
zstyle ':antidote:bundle' file \$ZDOTDIR/.zplugins.txt
zstyle ':antidote:static' file \$ZDOTDIR/.zplugins.txt"
  fixture_session <<<'antidote load 2>&1 | subenv ZDOTDIR'
  assert_output "antidote: bundle file and static file are the same '\$ZDOTDIR/.zplugins.txt'."
}

@test "load honors bundle and static file zstyles" {
  SESSION_PRELUDE="cp \$ZDOTDIR/.zplugins_fake_load \$ZDOTDIR/.zplugins.txt
zstyle ':antidote:bundle' file \$ZDOTDIR/.zplugins.txt
zstyle ':antidote:static' file \$ZDOTDIR/.zplugins.static.zsh"
  fixture_session <<'EOS'
antidote load >/dev/null && echo "load ok"
[[ -s $ZDOTDIR/.zplugins.static.zsh ]] && echo "static file written"
EOS
  assert_line "load ok"
  assert_line "static file written"
}

@test "load fails on a missing bundle file" {
  fixture_session <<<'antidote load /no/such/file.txt 2>&1'
  assert_output "antidote: bundle file not found '/no/such/file.txt'."
}

@test "load fails with exit 2 when the static file cannot be created" {
  SESSION_PRELUDE='zstyle ":antidote:load:checkfile" disabled true
touch $ZDOTDIR/.zplugins_err.txt $HOME/blocker'
  fixture_session <<<'antidote load $ZDOTDIR/.zplugins_err.txt $HOME/blocker/static.zsh 2>/dev/null'
  assert_failure 2
}

@test "load fails with exit 2 when the static file fails to source" {
  SESSION_PRELUDE='zstyle ":antidote:load:checkfile" disabled true
touch -t 202001010000 $ZDOTDIR/.zplugins_err.txt
print "false" > $ZDOTDIR/.zplugins_err.zsh'
  fixture_session <<<'antidote load $ZDOTDIR/.zplugins_err.txt $ZDOTDIR/.zplugins_err.zsh'
  assert_failure 2
}
