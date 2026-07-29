#!/usr/bin/env bats
# antidote pin/unpin subcommand tests.
#
# These cover the pin/unpin commands, which rewrite bundle lines.
# tests/bats/pin.bats covers the pin: annotation itself, which is what
# `antidote bundle` consumes. The pintest/pinme fixture has three
# commits, tagged v1.0.0 and v1.1.0, with v1.2.0 as HEAD.

load helpers/common

setup() {
  antidote_common_setup
  antidote_test_home
  ZSTYLES="zstyle ':antidote:test:version' show-sha off
zstyle ':antidote:test:git' autostash off"
  PINDIR="$AHOME/fakegitsite.com/pintest/pinme"
  PLUGINSFILE="$ZDOTDIR/.zsh_plugins.txt"
}

# Clone pinme so pin has something on disk to resolve against.
clone_pinme() {
  antidote bundle 'pintest/pinme' &>/dev/null
}

# Capture stdout only. bats `run` folds stderr into $output, which hides
# whether a warning leaked into the bundle-line payload.
run_out() {
  local rc=0
  output=$("$@" 2>/dev/null) || rc=$?
  status=$rc
  mapfile -t lines <<<"$output"
}

@test "pin adds a full SHA to an unpinned bundle argument" {
  clone_pinme
  run antidote pin 'pintest/pinme'
  assert_success
  assert_output "pintest/pinme pin:$PIN_V120"
}

@test "pin preserves other annotations on the line" {
  clone_pinme
  run antidote pin 'pintest/pinme kind:clone'
  assert_success
  assert_output "pintest/pinme kind:clone pin:$PIN_V120"
}

@test "pin leaves an already-valid pin alone" {
  clone_pinme
  run antidote pin "pintest/pinme pin:$PIN_V100"
  assert_success
  assert_output "pintest/pinme pin:$PIN_V100"
}

@test "pin --force re-resolves a valid pin from the checkout" {
  clone_pinme
  run antidote pin --force "pintest/pinme pin:$PIN_V100"
  assert_success
  assert_output "pintest/pinme pin:$PIN_V120"
}

@test "pin --force keeps annotation order when replacing a pin" {
  clone_pinme
  run antidote pin -f "pintest/pinme pin:$PIN_V100 kind:clone"
  assert_success
  assert_output "pintest/pinme pin:$PIN_V120 kind:clone"
}

@test "pin expands a short SHA without --force" {
  clone_pinme
  run antidote pin "pintest/pinme pin:${PIN_V100:0:7}"
  assert_success
  assert_output "pintest/pinme pin:$PIN_V100"
}

@test "pin resolves a tag to the SHA it points at" {
  clone_pinme
  run antidote pin 'pintest/pinme pin:v1.1.0'
  assert_success
  assert_output "pintest/pinme pin:$PIN_V110"
}

@test "pin fails on a ref that does not exist" {
  clone_pinme
  run antidote pin 'pintest/pinme pin:v9.9.9'
  assert_failure
  assert_output --partial "v9.9.9"
}

@test "pin clones a bundle that is not cloned yet" {
  # run_out, so clone progress on stderr cannot pass for bundle output.
  run_out antidote pin 'pintest/pinme'
  assert_success
  assert_output "pintest/pinme pin:$PIN_V120"
  assert [ -d "$PINDIR" ]
}

@test "pin clones missing bundles from a whole file" {
  printf '%s\n' 'pintest/pinme' 'foo/bar' >"$PLUGINSFILE"
  run antidote pin -i
  assert_success
  run cat "$PLUGINSFILE"
  assert_line --index 0 "pintest/pinme pin:$PIN_V120"
  assert_line --index 1 --regexp '^foo/bar pin:[0-9a-f]{40}$'
}

@test "pin fails on a bundle that cannot be cloned" {
  run antidote pin 'nope/nope'
  assert_failure
  assert_output --partial "unable to clone"
}

@test "pin reads bundle lines from stdin" {
  clone_pinme
  run antidote pin <<<'pintest/pinme'
  assert_success
  assert_output "pintest/pinme pin:$PIN_V120"
}

@test "pin with no arguments reads the plugins file" {
  clone_pinme
  printf '%s\n' 'pintest/pinme' >"$PLUGINSFILE"
  run antidote pin
  assert_success
  assert_output "pintest/pinme pin:$PIN_V120"
}

@test "pin --file reads the given file" {
  clone_pinme
  printf '%s\n' 'pintest/pinme' >"$ZDOTDIR/other.txt"
  printf '%s\n' '# not this one' >"$PLUGINSFILE"
  run antidote pin --file "$ZDOTDIR/other.txt"
  assert_success
  assert_output "pintest/pinme pin:$PIN_V120"
}

@test "pin --file with bundle arguments is an error" {
  clone_pinme
  run antidote pin --file "$PLUGINSFILE" 'pintest/pinme'
  assert_failure
  assert_output --partial "--file"
}

@test "pin preserves comments, blank lines, and order" {
  clone_pinme
  cat >"$PLUGINSFILE" <<'EOF'
# my plugins

pintest/pinme

# trailing comment
EOF
  run antidote pin
  assert_success
  expect "# my plugins

pintest/pinme pin:$PIN_V120

# trailing comment"
}

@test "pin inserts before a trailing inline comment" {
  clone_pinme
  run antidote pin 'pintest/pinme kind:clone  # my plugin'
  assert_success
  assert_output "pintest/pinme kind:clone pin:$PIN_V120  # my plugin"
}

@test "pin passes non-repo bundles through untouched" {
  clone_pinme
  run antidote pin '/some/local/path'
  assert_success
  assert_output '/some/local/path'
}

@test "pin gives every entry of a shared repo the same SHA" {
  antidote bundle 'ohmy/ohmy kind:clone' &>/dev/null
  printf '%s\n' 'ohmy/ohmy path:plugins/foo' 'ohmy/ohmy path:plugins/bar' >"$PLUGINSFILE"
  run antidote pin
  assert_success
  sha=$(git -C "$AHOME/fakegitsite.com/ohmy/ohmy" rev-parse HEAD)
  expect "ohmy/ohmy path:plugins/foo pin:$sha
ohmy/ohmy path:plugins/bar pin:$sha"
  run antidote __private__ bundle_check_critical <<<"$output"
  assert_success
}

@test "pin annotates the using: line, not its subplugins" {
  antidote bundle 'ohmy/ohmy kind:clone' &>/dev/null
  printf '%s\n' 'using:ohmy/ohmy path:plugins' 'foo' >"$PLUGINSFILE"
  run antidote pin
  assert_success
  sha=$(git -C "$AHOME/fakegitsite.com/ohmy/ohmy" rev-parse HEAD)
  expect "using:ohmy/ohmy path:plugins pin:$sha
foo"
}

@test "unpin removes the pin and leaves the rest of the line" {
  clone_pinme
  run antidote unpin "pintest/pinme pin:$PIN_V100 kind:clone"
  assert_success
  assert_output 'pintest/pinme kind:clone'
}

@test "unpin leaves an unpinned line alone" {
  clone_pinme
  run antidote unpin 'pintest/pinme kind:clone'
  assert_success
  assert_output 'pintest/pinme kind:clone'
}

@test "unpin rejects --force" {
  clone_pinme
  run antidote unpin -f 'pintest/pinme'
  assert_failure
}

@test "unpin then bundle returns the repo to its branch" {
  antidote bundle "pintest/pinme pin:$PIN_V100" >/dev/null
  printf '%s\n' "pintest/pinme pin:$PIN_V100" >"$PLUGINSFILE"
  run antidote unpin -i
  assert_success
  antidote bundle <"$PLUGINSFILE" >/dev/null
  run git -C "$PINDIR" config --get antidote.pin
  assert_failure
  run git -C "$PINDIR" rev-parse --abbrev-ref HEAD
  assert_output 'main'
}

@test "pin without -i does not modify the file" {
  clone_pinme
  printf '%s\n' 'pintest/pinme' >"$PLUGINSFILE"
  run antidote pin
  assert_success
  run cat "$PLUGINSFILE"
  assert_output 'pintest/pinme'
}

@test "pin -i rewrites the file and prints nothing to stdout" {
  clone_pinme
  printf '%s\n' 'pintest/pinme' >"$PLUGINSFILE"
  run_out antidote pin -i
  assert_success
  assert_output ''
  run cat "$PLUGINSFILE"
  assert_output "pintest/pinme pin:$PIN_V120"
}

@test "pin -i leaves a backup of the original" {
  clone_pinme
  printf '%s\n' 'pintest/pinme' >"$PLUGINSFILE"
  antidote pin -i 2>/dev/null
  run bash -c "cat '$ZDOTDIR'/.zsh_plugins.*.bak"
  assert_success
  assert_output 'pintest/pinme'
}

@test "pin -i with bundle arguments is an error" {
  clone_pinme
  run antidote pin -i 'pintest/pinme'
  assert_failure
  assert_output --partial '-i'
}

@test "pin warnings go to stderr, not the bundle output" {
  clone_pinme
  printf '%s\n' 'pintest/pinme' 'nope/nope' >"$PLUGINSFILE"
  run_out antidote pin
  assert_success
  assert_output "pintest/pinme pin:$PIN_V120
nope/nope"
}

@test "pin refuses input with parse errors" {
  clone_pinme
  printf '%s\n' 'pintest/pinme oops' >"$PLUGINSFILE"
  run_out antidote pin
  assert_failure
  assert_output ''
}

@test "pin round-trips a CRLF file" {
  clone_pinme
  printf 'pintest/pinme\r\n' >"$PLUGINSFILE"
  antidote pin >"$BATS_TEST_TMPDIR/out.txt"
  run od -c "$BATS_TEST_TMPDIR/out.txt"
  assert_output --partial '\r'
}

@test "pin -i is idempotent" {
  clone_pinme
  printf '%s\n' 'pintest/pinme' >"$PLUGINSFILE"
  antidote pin -i 2>/dev/null
  first=$(cat "$PLUGINSFILE")
  antidote pin -i 2>/dev/null
  run cat "$PLUGINSFILE"
  assert_output "$first"
}

@test "pin -i leaves the file alone when nothing changes" {
  clone_pinme
  printf '%s\n' "pintest/pinme pin:$PIN_V120" >"$PLUGINSFILE"
  before=$(stat -c %Y "$PLUGINSFILE" 2>/dev/null || stat -f %m "$PLUGINSFILE")
  run antidote pin -i
  assert_success
  assert_output --partial 'nothing to do'
  after=$(stat -c %Y "$PLUGINSFILE" 2>/dev/null || stat -f %m "$PLUGINSFILE")
  assert_equal "$before" "$after"
  run bash -c "ls '$ZDOTDIR'/.zsh_plugins.*.bak 2>/dev/null | wc -l | tr -d ' '"
  assert_output '0'
}

# --force on a pin that resolves right back to itself is not a change,
# and must not cost a backup of an identical file.
@test "pin -i --force leaves the file alone when pins resolve to themselves" {
  antidote bundle "pintest/pinme pin:$PIN_V100" &>/dev/null
  printf '%s\n' "pintest/pinme pin:$PIN_V100" >"$PLUGINSFILE"
  run antidote pin -i --force
  assert_success
  assert_output --partial 'nothing to do'
  run bash -c "ls '$ZDOTDIR'/.zsh_plugins.*.bak 2>/dev/null | wc -l | tr -d ' '"
  assert_output '0'
}

@test "pin -i never clobbers an existing backup" {
  clone_pinme
  printf '%s\n' 'pintest/pinme' >"$PLUGINSFILE"
  antidote pin -i 2>/dev/null
  # A second changing run in the same second must not overwrite the first
  # backup, which is the only copy of the original.
  printf '%s\n' 'pintest/pinme pin:v1.0.0' >"$PLUGINSFILE"
  antidote pin -i 2>/dev/null
  run bash -c "grep -lx 'pintest/pinme' '$ZDOTDIR'/.zsh_plugins.*.bak | wc -l | tr -d ' '"
  assert_output '1'
  run bash -c "ls '$ZDOTDIR'/.zsh_plugins.*.bak | wc -l | tr -d ' '"
  assert_output '2'
}

@test "every pin stderr line is a legal plugins file comment" {
  printf '%s\n' 'pintest/pinme' 'nope/nope' >"$PLUGINSFILE"
  antidote pin >/dev/null 2>"$BATS_TEST_TMPDIR/err.txt"
  run cat "$BATS_TEST_TMPDIR/err.txt"
  assert_output --partial '# antidote cloning pintest/pinme...'
  assert_output --partial '# antidote: pin: unable to clone nope/nope'
  # Merging the streams must not corrupt the file, so no bare line.
  run bash -c "grep -cv '^#' '$BATS_TEST_TMPDIR/err.txt' || true"
  assert_output '0'
}

@test "pin stderr has no escape codes when stderr is not a terminal" {
  clone_pinme
  printf '%s\n' 'pintest/pinme' >"$PLUGINSFILE"
  antidote pin -i 2>"$BATS_TEST_TMPDIR/err.txt"
  run bash -c "grep -c $'\033' '$BATS_TEST_TMPDIR/err.txt' || true"
  assert_output '0'
}

# --- as-of ---------------------------------------------------------
# The dino/saur fixture has commits dated ~900, ~400, and ~1 days back.

@test "pin --as-of picks the newest commit at or before the date" {
  antidote bundle 'dino/saur kind:clone' &>/dev/null
  run_out antidote pin --as-of '200 days ago' 'dino/saur'
  assert_success
  assert_output "dino/saur pin:$(tgit -C "$AHOME/fakegitsite.com/dino/saur" \
    rev-list --before='200 days ago' -1 origin/main)"
}

@test "pin --as-of now picks the newest commit" {
  antidote bundle 'dino/saur kind:clone' &>/dev/null
  run_out antidote pin --as-of now 'dino/saur'
  assert_success
  assert_output "dino/saur pin:$(tgit -C "$AHOME/fakegitsite.com/dino/saur" \
    rev-parse origin/main)"
}

@test "pin --as-of reaches back past an older commit" {
  antidote bundle 'dino/saur kind:clone' &>/dev/null
  run_out antidote pin --as-of '500 days ago' 'dino/saur'
  assert_success
  assert_output "dino/saur pin:$(tgit -C "$AHOME/fakegitsite.com/dino/saur" \
    rev-list --before='500 days ago' -1 origin/main)"
}

@test "pin --as-of fails when nothing is that old" {
  antidote bundle 'dino/saur kind:clone' &>/dev/null
  run antidote pin --as-of '2000 days ago' 'dino/saur'
  assert_failure
  assert_output --partial 'no commit at or before'
}

@test "pin --as-of rejects a date git would read as now" {
  antidote bundle 'dino/saur kind:clone' &>/dev/null
  run antidote pin --as-of 'not a date at all' 'dino/saur'
  assert_failure
  assert_output --partial 'is not a date git understands'
}

@test "pin --as-of leaves a valid pin alone without --force" {
  antidote bundle 'dino/saur kind:clone' &>/dev/null
  sha=$(tgit -C "$AHOME/fakegitsite.com/dino/saur" rev-parse origin/main)
  run_out antidote pin --as-of '200 days ago' "dino/saur pin:$sha"
  assert_success
  assert_output "dino/saur pin:$sha"
}

@test "pin --force --as-of re-dates an existing pin" {
  antidote bundle 'dino/saur kind:clone' &>/dev/null
  sha=$(tgit -C "$AHOME/fakegitsite.com/dino/saur" rev-parse origin/main)
  run_out antidote pin -f --as-of '200 days ago' "dino/saur pin:$sha"
  assert_success
  assert_output "dino/saur pin:$(tgit -C "$AHOME/fakegitsite.com/dino/saur" \
    rev-list --before='200 days ago' -1 origin/main)"
}

@test "an explicit pin: ref beats --as-of for that bundle" {
  clone_pinme
  run_out antidote pin --as-of '1 day ago' "pintest/pinme pin:v1.0.0"
  assert_success
  assert_output "pintest/pinme pin:$PIN_V100"
}

@test "pin --as-of refuses a bundle held shallow by config" {
  ZSTYLES+="
zstyle ':antidote:bundle:dino/saur' shallow yes"
  antidote bundle 'dino/saur kind:clone' &>/dev/null
  run antidote pin --as-of '200 days ago' 'dino/saur'
  assert_failure
  assert_output --partial 'held shallow by config'
}

@test "unpin rejects --as-of" {
  clone_pinme
  run antidote unpin --as-of now 'pintest/pinme'
  assert_failure
}

# The clone's deepen is normally disowned, so a date lookup right after a
# fresh clone can race it. Force the real-world timing to prove it does not.
@test "pin --as-of works on a bundle cloned in the same run" {
  ZSTYLES+="
zstyle ':antidote:test:git' background-deepen yes"
  run_out antidote pin --as-of '200 days ago' 'dino/saur'
  assert_success
  assert_output --regexp '^dino/saur pin:[0-9a-f]{40}$'
}

@test "pin's clone is deep, so a pinned bundle keeps its history" {
  ZSTYLES+="
zstyle ':antidote:test:git' background-deepen yes"
  run_out antidote pin 'dino/saur'
  assert_success
  run tgit -C "$AHOME/fakegitsite.com/dino/saur" rev-parse --is-shallow-repository
  assert_output 'false'
}

@test "pin's clone still honors a shallow zstyle" {
  ZSTYLES+="
zstyle ':antidote:bundle:dino/saur' shallow yes
zstyle ':antidote:test:git' background-deepen yes"
  run_out antidote pin 'dino/saur'
  assert_success
  run tgit -C "$AHOME/fakegitsite.com/dino/saur" rev-parse --is-shallow-repository
  assert_output 'true'
}
