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

# git chatters on its own during a clone, eg "warning: redirecting to"
# for any URL the host redirects. Static mode sources this output, so a
# line that is not part of the script has to stay off stdout.
@test "git chatter during a clone stays out of the script" {
  local shim="$BATS_TEST_TMPDIR/chattygit"
  {
    echo '#!/usr/bin/env bash'
    echo 'if [ "$1" = clone ]; then'
    echo '  echo "warning: redirecting to https://fakegitsite.com/pintest/pinme/" >&2'
    echo 'fi'
    echo 'exec git "$@"'
  } >"$shim"
  chmod +x "$shim"
  ZSTYLES="zstyle ':antidote:git' cmd '$shim'"

  # stdout alone is the contract here, so drop stderr rather than let
  # bats merge the two streams together.
  local script
  script=$(antidote bundle pintest/pinme 2>/dev/null)
  run printf '%s\n' "$script"
  subenv_output ANTIDOTE_HOME
  expect 'fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/pintest/pinme" )
source "$ANTIDOTE_HOME/fakegitsite.com/pintest/pinme/pinme.plugin.zsh"'
}

# an entry that already failed to parse must not cost a clone; the scripter
# drops it either way
@test "a bundle with an error is not cloned" {
  run antidote bundle <<'EOS'
totally/bogusrepo junk
foo/bar
EOS
  assert_failure 1
  refute_line --partial "cloning totally/bogusrepo"
  assert_line --partial "Expecting 'key:value' form for annotation 'junk'"
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

# git removes the clone target on failure but keeps the parent dirs it
# had to create, so a mistyped bundle salts ANTIDOTE_HOME with empties.
@test "a failed clone leaves no directories behind" {
  local before after
  before=$(cd "$AHOME" && find . -type d | sort)
  run antidote bundle 'https://fakegitsite.com/zsh-users/zsh-autosuggestions/src/foo.zsh'
  assert_failure 1
  after=$(cd "$AHOME" && find . -type d | sort)
  run diff <(printf '%s\n' "$before") <(printf '%s\n' "$after")
  assert_success
}

# Those leftovers used to satisfy the "already cloned" check, so fixing
# the bundle line produced a static file pointing at an empty directory.
@test "a corrected bundle still clones after a failed one" {
  antidote bundle 'https://fakegitsite.com/zsh-users/zsh-autosuggestions/src/foo.zsh' &>/dev/null || true
  run antidote bundle zsh-users/zsh-autosuggestions
  assert_success
  subenv_output ANTIDOTE_HOME
  assert_line 'source "$ANTIDOTE_HOME/fakegitsite.com/zsh-users/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh"'
  [ -f "$AHOME/fakegitsite.com/zsh-users/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh" ]
}

# A clone carries empty dirs of its own inside .git (objects/info,
# refs/tags), which rmdir would take. Pruning must never enter one.
@test "pruning leaves a real clone alone" {
  local repo="$AHOME/fakegitsite.com/foo/bar"
  local before after
  before=$(find "$repo" | sort)
  run antidote __private__ clone_dir_prune "$repo"
  assert_success
  after=$(find "$repo" | sort)
  run diff <(printf '%s\n' "$before") <(printf '%s\n' "$after")
  assert_success
}

# Pruning walks upward, so it must refuse the home itself and anything
# living outside it.
@test "pruning stays inside ANTIDOTE_HOME" {
  mkdir -p "$AHOME/junk/chain" "$TESTHOME/outside/a/b"

  run antidote __private__ clone_dir_prune "$AHOME"
  assert_success
  [ -d "$AHOME" ]

  run antidote __private__ clone_dir_prune "$TESTHOME/outside"
  assert_success
  [ -d "$TESTHOME/outside/a/b" ]

  run antidote __private__ clone_dir_prune "$AHOME/junk/chain"
  assert_success
  [ ! -d "$AHOME/junk" ]
}

# Pruning always succeeds. Its callers are parallel jobs whose status
# becomes the bundle run's exit code, so halting early is not a failure.
@test "pruning succeeds when it halts on a non-empty parent" {
  mkdir -p "$AHOME/site/junk/chain" "$AHOME/site/keep"
  echo 'x' >"$AHOME/site/keep/f.zsh"

  run antidote __private__ clone_dir_prune "$AHOME/site/junk/chain"
  assert_success
  [ ! -d "$AHOME/site/junk" ]
  [ -f "$AHOME/site/keep/f.zsh" ]
}

# A bundle file of only kind:clone entries emits nothing, but that is
# success, not failure.
@test "clone-only bundles succeed with no output" {
  run antidote bundle 'foo/baz kind:clone'
  assert_success
  run antidote bundle 'foo/baz kind:clone'
  assert_success
}

# A theme repo can ship more than one .zsh-theme (powerlevel10k also
# ships powerlevel9k). Source the one named for the repo, not both.
@test "a theme repo sources only the theme named for the repo" {
  run antidote bundle themes/ohmytheme
  subenv_output ANTIDOTE_HOME
  expect '# antidote cloning themes/ohmytheme...
fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/themes/ohmytheme" )
source "$ANTIDOTE_HOME/fakegitsite.com/themes/ohmytheme/ohmytheme.zsh-theme"'
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

# Dynamic mode captures bundle output with a command substitution, so a
# deepen still holding that fd stalls the shell. Slow git stands in for
# a repo with a big history.
@test "a clone does not wait on the background unshallow" {
  local shim="$BATS_TEST_TMPDIR/slowgit" start elapsed out
  {
    echo '#!/usr/bin/env bash'
    echo 'for a in "$@"; do [ "$a" = "--unshallow" ] && exec sleep 10; done'
    echo 'exec git "$@"'
  } >"$shim"
  chmod +x "$shim"

  ZSTYLES="zstyle ':antidote:bundle:*' shallow no
zstyle ':antidote:test:git' background-deepen yes
zstyle ':antidote:git' cmd '$shim'"

  start=$SECONDS
  out=$(antidote bundle pintest/pinme 2>/dev/null)
  elapsed=$((SECONDS - start))

  [ -n "$out" ]
  [ "$elapsed" -lt 5 ]
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
