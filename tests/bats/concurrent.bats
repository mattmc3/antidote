#!/usr/bin/env bats
# Two antidote processes touching one bundle at the same time: a shell
# storm cloning a missing repo, or a manual update racing a scheduled
# one. git serializes its own work with lock files and fails the loser,
# so antidote has to keep same-repo work from overlapping.

load helpers/common

setup() {
  antidote_common_setup
  antidote_test_home
  ZSTYLES="zstyle ':antidote:test:version' show-sha off
zstyle ':antidote:test:git' autostash off"
  BAZDIR="$AHOME/fakegitsite.com/foo/baz"
}

# Exit codes go to files because bats runs the body under set -e: a
# failing command inside a backgrounded subshell kills it before an
# `echo $?` on the next line ever runs.
run_parallel() {
  local n="$1"; shift
  local i
  for i in $(seq 1 "$n"); do
    ( if "$@" >"$BATS_TEST_TMPDIR/out.$i" 2>&1; then echo 0; else echo "$?"; fi \
        >"$BATS_TEST_TMPDIR/rc.$i" ) &
  done
  wait
}

parallel_rcs() {
  cat "$BATS_TEST_TMPDIR"/rc.* | sort -u | tr '\n' ' '
}

# Rounds, not one burst: a local fixture clone can finish before the
# other processes even look, so a single round passes by luck.
@test "concurrent clones of one bundle all succeed" {
  local round
  for round in 1 2 3; do
    rm -rf "$AHOME/fakegitsite.com/foo/bar"
    run_parallel 6 antidote bundle foo/bar
    assert_equal "round $round rcs: $(parallel_rcs)" "round $round rcs: 0 "
    [ -d "$AHOME/fakegitsite.com/foo/bar/.git" ]

    # A loser whose clone was refused still exits 0 (the winner's clone
    # is there), so the git error is what proves the runs overlapped.
    run grep -l 'unexpected git error' "$BATS_TEST_TMPDIR"/out.*
    assert_output ""
  done
}

# Rounds, not one burst: a single round of updates finishes clean often
# enough on local fixtures to pass by luck.
@test "concurrent updates of one bundle all succeed" {
  antidote_clone_fixtures
  tgit_deepen "$BAZDIR"
  local round sha_before
  for round in 1 2 3; do
    tgit -C "$BAZDIR" reset --quiet --hard HEAD~1
    sha_before=$(tgit -C "$BAZDIR" rev-parse --short HEAD)
    run_parallel 8 antidote update
    assert_equal "round $round rcs: $(parallel_rcs)" "round $round rcs: 0 "
    run tgit -C "$BAZDIR" rev-parse --short HEAD
    refute_output "$sha_before"
  done
}
