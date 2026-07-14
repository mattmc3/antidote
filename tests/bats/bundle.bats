#!/usr/bin/env bats
# antidote bundle command tests (ported from tests/test_cmd_bundle.md).
# Many 'bundle' tests could just as well be 'script' tests; script.md
# finds scripting issues, this covers actual bundling in bulk.

load helpers/common

setup() { antidote_common_setup; }

bundle_session() {
  SESSION_PRELUDE='antidote bundle <$ZDOTDIR/.base_test_fixtures.txt &>/dev/null' \
    run_session
}

@test "bundle generates the static file for the ZDOTDIR plugins file" {
  bundle_session <<'EOS'
antidote bundle <$ZDOTDIR/.zsh_plugins.txt >$ZDOTDIR/.zsh_plugins.zsh
cat $ZDOTDIR/.zsh_plugins.zsh | subenv
EOS
  expect "$(cat "$PRJDIR/tests/testdata/.zsh_plugins.zsh")"
}

# Test |piping, <redirection, and --args
@test "bundle accepts args, pipes, and redirection" {
  bundle_session <<'EOS'
ANTIDOTE_HOME=$HOME/.cache/antidote
antidote bundle foo/bar | subenv ANTIDOTE_HOME
echo 'foo/bar' | antidote bundle | subenv ANTIDOTE_HOME
echo 'git@fakegitsite.com:foo/qux' >$ZDOTDIR/.zsh_plugins_simple.txt
antidote bundle <$ZDOTDIR/.zsh_plugins_simple.txt | subenv ANTIDOTE_HOME
EOS
  expect "$(cat "$PRJDIR/tests/testdata/script-foobar.zsh" "$PRJDIR/tests/testdata/script-foobar.zsh" "$PRJDIR/tests/testdata/script-fooqux.zsh")"
}

@test "bundle accepts args, pipes, and redirection with escaped path-style" {
  bundle_session <<'EOS'
zstyle ':antidote:bundle' path-style escaped
ANTIDOTE_HOME=$HOME/.cache/antibody
antidote bundle foo/bar 2>/dev/null | subenv ANTIDOTE_HOME
echo 'foo/bar' | antidote bundle 2>/dev/null | subenv ANTIDOTE_HOME
echo 'git@fakegitsite.com:foo/qux' >$ZDOTDIR/.zsh_plugins_simple.txt
antidote bundle <$ZDOTDIR/.zsh_plugins_simple.txt 2>/dev/null | subenv ANTIDOTE_HOME
EOS
  expect "$(cat "$PRJDIR/tests/testdata/antibody/script-foobar.zsh" "$PRJDIR/tests/testdata/antibody/script-foobar.zsh" "$PRJDIR/tests/testdata/antibody/script-fooqux.zsh")"
}

@test "multiple defers only load zsh-defer once" {
  bundle_session <<'EOS'
antidote bundle 'foo/bar kind:defer\nbar/baz kind:defer' | subenv ANTIDOTE_HOME
EOS
  expected=$(cat <<'EOF'
if ! (( $+functions[zsh-defer] )); then
  fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/getantidote/zsh-defer" )
  source "$ANTIDOTE_HOME/fakegitsite.com/getantidote/zsh-defer/zsh-defer.plugin.zsh"
fi
fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/foo/bar" )
zsh-defer source "$ANTIDOTE_HOME/fakegitsite.com/foo/bar/bar.plugin.zsh"
fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/bar/baz" )
zsh-defer source "$ANTIDOTE_HOME/fakegitsite.com/bar/baz/baz.plugin.zsh"
EOF
)
  expect "$expected"
}

# Note: bad kind still exits 0 (only the parser sets exit 1); this
# asserts the error message, matching the original clitest.
@test "bad kind values report an error" {
  bundle_session <<'EOS'
echo "foo/bar\nfoo/baz kind:whoops" | antidote bundle 2>&1 >/dev/null
EOS
  assert_line "# antidote: error: unexpected kind value: 'whoops'"
}

# A bundle file of only kind:clone entries emits nothing, but that is
# success, not failure.
@test "clone-only bundles succeed with no output" {
  bundle_session <<'EOS'
antidote bundle 'foo/baz kind:clone' 2>/dev/null; echo "first exit: $?"
antidote bundle 'foo/baz kind:clone' 2>/dev/null; echo "second exit: $?"
EOS
  assert_line --index 0 "first exit: 0"
  assert_line --index 1 "second exit: 0"
}
