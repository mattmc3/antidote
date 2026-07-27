#!/usr/bin/env bats
# antidote bundle command tests.
# Many 'bundle' tests could just as well be 'script' tests; script.bats
# finds scripting issues, this covers actual bundling in bulk.

load helpers/common

setup_file() { antidote_fixture_proto; }

setup() {
  antidote_common_setup
  antidote_test_home_cached
}

@test "bundle generates the static file for the ZDOTDIR plugins file" {
  run antidote bundle <"$ZDOTDIR/.zsh_plugins.txt"
  subenv_output
  expect "$(cat "$PRJDIR/tests/testdata/.zsh_plugins.zsh")"
}

# Test |piping, <redirection, and --args
@test "bundle accepts args, pipes, and redirection" {
  run antidote bundle foo/bar
  subenv_output ANTIDOTE_HOME
  expect "$(cat "$PRJDIR/tests/testdata/script-foobar.zsh")"

  run antidote bundle <<<'foo/bar'
  subenv_output ANTIDOTE_HOME
  expect "$(cat "$PRJDIR/tests/testdata/script-foobar.zsh")"

  echo 'git@fakegitsite.com:foo/qux' >"$ZDOTDIR/.zsh_plugins_simple.txt"
  run antidote bundle <"$ZDOTDIR/.zsh_plugins_simple.txt"
  subenv_output ANTIDOTE_HOME
  expect "$(cat "$PRJDIR/tests/testdata/script-fooqux.zsh")"
}

@test "bundle accepts args, pipes, and redirection with escaped path-style" {
  AHOME="$TESTHOME/.cache/antibody"
  ZSTYLES="zstyle ':antidote:bundle' path-style escaped"

  # The prototype home only holds antidote-style clones, so warm the
  # antibody home first: run merges stderr, and a cloning notice there
  # would show up as unexpected output.
  antidote bundle foo/bar &>/dev/null
  antidote bundle 'git@fakegitsite.com:foo/qux' &>/dev/null

  run antidote bundle foo/bar
  subenv_output ANTIDOTE_HOME
  expect "$(cat "$PRJDIR/tests/testdata/antibody/script-foobar.zsh")"

  run antidote bundle <<<'foo/bar'
  subenv_output ANTIDOTE_HOME
  expect "$(cat "$PRJDIR/tests/testdata/antibody/script-foobar.zsh")"

  echo 'git@fakegitsite.com:foo/qux' >"$ZDOTDIR/.zsh_plugins_simple.txt"
  run antidote bundle <"$ZDOTDIR/.zsh_plugins_simple.txt"
  subenv_output ANTIDOTE_HOME
  expect "$(cat "$PRJDIR/tests/testdata/antibody/script-fooqux.zsh")"
}

@test "multiple defers only load zsh-defer once" {
  run antidote bundle 'foo/bar kind:defer\nbar/baz kind:defer'
  subenv_output ANTIDOTE_HOME
  expect 'if ! (( $+functions[zsh-defer] )); then
  fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/getantidote/zsh-defer" )
  source "$ANTIDOTE_HOME/fakegitsite.com/getantidote/zsh-defer/zsh-defer.plugin.zsh"
fi
fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/foo/bar" )
zsh-defer source "$ANTIDOTE_HOME/fakegitsite.com/foo/bar/bar.plugin.zsh"
fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/bar/baz" )
zsh-defer source "$ANTIDOTE_HOME/fakegitsite.com/bar/baz/baz.plugin.zsh"'
}

# A failed clone must not take down the rest of the bundle run: the
# exit code reports the failure, the good bundles still come through.
@test "a bad repo mixed with good ones fails but emits the good" {
  run antidote bundle <<<$'foo/bar\ndoes-not/exist'
  assert_failure 1
  subenv_output ANTIDOTE_HOME
  assert_line 'source "$ANTIDOTE_HOME/fakegitsite.com/foo/bar/bar.plugin.zsh"'
}

# A bundle file of only kind:clone entries emits nothing, but that is
# success, not failure.
@test "clone-only bundles succeed with no output" {
  run antidote bundle 'foo/baz kind:clone'
  assert_success
  run antidote bundle 'foo/baz kind:clone'
  assert_success
}

# Tests deepen in the foreground, so opt this one back into the real
# disowned job. It has no completion signal, so poll for it. Polling to
# completion also leaves nothing running for teardown to trip over.
@test "a clone kicks off a background unshallow" {
  ZSTYLES="zstyle ':antidote:bundle:*' shallow no
zstyle ':antidote:test:git' background-deepen yes"
  local dir="$AHOME/fakegitsite.com/pintest/pinme" i

  run antidote bundle 'pintest/pinme kind:clone'
  assert_success

  for i in {1..100}; do
    [[ "$(git -C "$dir" rev-parse --is-shallow-repository)" == false ]] && break
    sleep 0.1
  done
  run git -C "$dir" rev-parse --is-shallow-repository
  assert_output "false"
}

# A pin names one commit, so there is no history worth fetching.
@test "a pinned clone is left shallow" {
  ZSTYLES="zstyle ':antidote:bundle:*' shallow no"
  local dir="$AHOME/fakegitsite.com/pintest/pinme"

  run antidote bundle "pintest/pinme kind:clone pin:$PIN_V110"
  assert_success

  sleep 1
  run git -C "$dir" rev-parse --is-shallow-repository
  assert_output "true"
}

# Keep at bottom of file because this messes up syntax highlighting
@test "bad kind values fail" {
  run antidote bundle <<<$'foo/bar\nfoo/baz kind:whoops'
  assert_failure 1
  assert_line "# antidote: error: unexpected kind value: 'whoops'"
}
