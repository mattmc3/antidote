#!/usr/bin/env bats
# antidote help tests

load helpers/common

setup() { antidote_common_setup; }

# Man page header check for a topic via `antidote help <topic>`,
# `antidote <topic> --help`, and `antidote <topic> -h`.
manpage_check() {
  local topic=$1 page=$2 header
  header="$page(1) Antidote Manual $page(1)"
  run_session <<EOS
antidote help $topic | head -n 1 | sed 's/  */ /g'
antidote $topic --help | head -n 1 | sed 's/  */ /g'
antidote $topic -h | head -n 1 | sed 's/  */ /g'
EOS
  assert_success
  assert_line --index 0 "$header"
  assert_line --index 1 "$header"
  assert_line --index 2 "$header"
}

# -h/--help flag plumbing is covered in antidote_core.bats.
@test "bare help command works" {
  run_session <<<'antidote help &>/dev/null; echo "help: $?"'
  assert_output "help: 0"
}

@test "man antidote works and MANPATH is set" {
  run_session <<'EOS'
PAGER=cat man antidote | head -n 1 | sed 's/  */ /g'
[[ "$MANPATH" == *"$T_PRJDIR/man:"* ]] && echo "MANPATH ok"
EOS
  assert_success
  assert_line --index 0 "ANTIDOTE(1) Antidote Manual ANTIDOTE(1)"
  assert_line --index 1 "MANPATH ok"
}

@test "antidote help bundle" { manpage_check bundle ANTIDOTE-BUNDLE; }
@test "antidote help help" { manpage_check help ANTIDOTE-HELP; }
@test "antidote help home" { manpage_check home ANTIDOTE-HOME; }
@test "antidote help init" { manpage_check init ANTIDOTE-INIT; }
@test "antidote help install" { manpage_check install ANTIDOTE-INSTALL; }
@test "antidote help list" { manpage_check list ANTIDOTE-LIST; }
@test "antidote help load" { manpage_check load ANTIDOTE-LOAD; }
@test "antidote help path" { manpage_check path ANTIDOTE-PATH; }
@test "antidote help update" { manpage_check update ANTIDOTE-UPDATE; }

@test "unknown topic falls back to usage" {
  run_session <<<'antidote help foo'
  assert_failure 1
  assert_output "No manual entry for antidote-foo
$(cat "$PRJDIR/tests/testdata/usage_dispatch.txt")"
}

# The private usage helpers should not remain defined in the user's shell.
@test "no leaked usage helper functions" {
  run_session <<'EOS'
antidote -h >/dev/null
antidote help >/dev/null 2>&1
typeset -f __antidote_dispatch_usage >/dev/null || echo "no dispatch leak"
typeset -f __antidote_usage >/dev/null || echo "no help leak"
EOS
  assert_success
  assert_line "no dispatch leak"
  assert_line "no help leak"
}
