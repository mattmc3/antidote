# Shared bats harness for antidote tests.
#
# Two styles, in order of preference:
#
# 1. Canonical bats (default): `antidote_test_home` in setup(), then one
#    `run antidote ...` per statement with focused asserts. Works for
#    anything whose state lives on disk (clones, files) — the antidote()
#    wrapper runs antidote.zsh as a subprocess in an isolated HOME.
#
# 2. run_session: for behavior that needs a live zsh session (dynamic
#    `antidote init` mode, setopts, parent-shell wrappers like load and
#    autoloading). Arrange steps go in SESSION_PRELUDE; the session
#    body is act+assert and should stay around 5 lines or fewer.
#    Whole-output `expect` walls are only for script-generation and
#    golden-file tests, where the full output is the contract.

antidote_common_setup() {
  cd "$BATS_TEST_DIRNAME" || return 1
  while [[ ! -f antidote.zsh && "$PWD" != / ]]; do cd ..; done
  [[ -f antidote.zsh ]] || return 1
  PRJDIR=$PWD
  # Version tests assert against the source of truth, so version bumps
  # never touch test files.
  EXPECTED_VERSION=$(sed -n 's/.*ANTIDOTE_VERSION="\([^"]*\)".*/\1/p' antidote.zsh)
  [ -n "$EXPECTED_VERSION" ] || return 1
}

# Locate the generated git fixtures (tests/run pre-generates them).
antidote_fixture_dir() {
  local d="$PRJDIR/tests/fixtures"
  if [[ -d "$d/bare" && -f "$d/.git_version" &&
        "$(cat "$d/.git_version")" == "$(git --version)" ]]; then
    echo "$d"
  else
    echo /tmp/antidote-fixtures
  fi
}

# Build an isolated HOME for subprocess tests: tmp_home contents, the
# test config, and a gitconfig that maps fakegitsite.com to the local
# bare fixtures. Exports TESTHOME, ZDOTDIR, and AHOME.
antidote_test_home() {
  # Resolve symlinks (macOS /var/folders -> /private/var) so subprocess
  # path prefix checks against $HOME hold.
  mkdir -p "$BATS_TEST_TMPDIR/home"
  TESTHOME="$(cd "$BATS_TEST_TMPDIR/home" && pwd -P)"
  ZDOTDIR="$TESTHOME/.zsh"
  AHOME="$TESTHOME/.cache/antidote"
  mkdir -p "$ZDOTDIR" "$AHOME"
  cp -Rf "$PRJDIR/tests/tmp_home/." "$TESTHOME"
  local fixdir
  fixdir=$(antidote_fixture_dir)
  sed "s|/[^ \"]*/tests/fixtures/|${fixdir}/|g" "$fixdir/gitconfig" >"$TESTHOME/.gitconfig"
}

# Run antidote (or `antidote __private__ <fn>`) as a subprocess in the
# isolated test home. Extra zstyles go in $ZSTYLES.
# Set AHOME="" to test antidote's own ANTIDOTE_HOME resolution.
antidote() {
  ( cd "$TESTHOME" && env \
      -u XDG_CACHE_HOME -u XDG_DATA_HOME -u XDG_CONFIG_HOME \
      HOME="$TESTHOME" ZDOTDIR="$ZDOTDIR" T_PRJDIR="$PRJDIR" \
      ${AHOME:+ANTIDOTE_HOME="$AHOME"} \
      ANTIDOTE_CONFIG="$TESTHOME/.config/antidote/test_config.zsh" \
      ANTIDOTE_ZSTYLES="${ZSTYLES:-}" ${EXTRA_ENV:-} \
      zsh "$PRJDIR/antidote.zsh" "$@" )
}

# Clone the standard test fixtures into the test home, quietly.
antidote_clone_fixtures() {
  antidote bundle <"$ZDOTDIR/.base_test_fixtures.txt" &>/dev/null
}

# git against the test home, so the fixture gitconfig (insteadOf rules
# for fakegitsite.com) applies to fetch/pull.
tgit() {
  HOME="$TESTHOME" git "$@"
}

# SESSION_PRELUDE, when set, is injected after setup — use it for
# per-file shorthand. SESSION_SETUP overrides the setup function
# (default t_setup; real tests use t_setup_real). Never pipe INTO
# run_session: `run` would execute in a pipeline subshell and $output
# would be lost.
run_session() {
  local script="$BATS_TEST_TMPDIR/session.zsh"
  {
    echo "source ${PRJDIR}/tests/__init__.zsh || exit 9"
    echo "${SESSION_SETUP:-t_setup} || exit 9"
    [ -n "${SESSION_PRELUDE:-}" ] && printf '%s\n' "$SESSION_PRELUDE"
    cat
    echo "t_teardown"
  } >"$script"
  run env -i PATH="$PATH" PAGER=cat TERM=dumb zsh -f "$script"
}

# Compare $output against an expected string, showing a diff on failure.
expect() {
  if [ "$output" != "$1" ]; then
    echo "=== diff (expected vs got) ==="
    diff <(printf '%s\n' "$1") <(printf '%s\n' "$output") || true
    return 1
  fi
}
