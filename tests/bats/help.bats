#!/usr/bin/env bats
# antidote help tests (ported from tests/test_cmd_help.md)

load helpers/common

setup() { antidote_common_setup; }

# Man page header check for a topic via `antidote help <topic>`,
# `antidote <topic> --help`, and `antidote <topic> -h`.
manpage_check() {
  local topic=$1 page=$2
  run_session <<EOS
antidote help $topic | head -n 1 | sed 's/  */ /g'
antidote $topic --help | head -n 1 | sed 's/  */ /g'
antidote $topic -h | head -n 1 | sed 's/  */ /g'
EOS
  expect "$page(1) Antidote Manual $page(1)
$page(1) Antidote Manual $page(1)
$page(1) Antidote Manual $page(1)"
}

@test "help command and flags exist" {
  run_session <<'EOS'
antidote help &>/dev/null; echo $?
antidote -h &>/dev/null; echo $?
antidote --help &>/dev/null; echo $?
EOS
  expect "0
0
0"
}

@test "man antidote works and MANPATH is set" {
  run_session <<'EOS'
PAGER=cat man antidote | head -n 1 | sed 's/  */ /g'
[[ "$MANPATH" == *"$T_PRJDIR/man:"* ]] || echo "MANPATH not set properly"
EOS
  expect "ANTIDOTE(1) Antidote Manual ANTIDOTE(1)"
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
  run_session <<'EOS'
antidote help foo
EOS
  expected=$(cat <<'EOF'
No manual entry for antidote-foo
antidote - the cure to slow zsh plugin management

usage: antidote [<flags>] <command> [<args> ...]

flags:
  -h, --help            Show context-sensitive help
  -v, --version         Show application version
      --diagnostics     Show antidote and system diagnostics

commands:
  bundle    Clone bundle(s) and generate the static load script
  install   Clone a new bundle and add it to your plugins file
  update    Update antidote and its cloned bundles
  purge     Remove a cloned bundle
  home      Print where antidote is cloning bundles
  list      List cloned bundles
  path      Print the path of a cloned bundle
  snapshot  Save, restore, or list bundle snapshots
  init      Initialize the shell for dynamic bundles
  help      Show documentation
  load      Statically source all bundles from the plugins file
EOF
)
  expect "$expected"
}

# The private usage helpers should not remain defined in the user's shell.
@test "no leaked usage helper functions" {
  run_session <<'EOS'
antidote -h >/dev/null
antidote help >/dev/null 2>&1
typeset -f __antidote_dispatch_usage >/dev/null || echo "no dispatch leak"
typeset -f __antidote_usage >/dev/null || echo "no help leak"
EOS
  expect "no dispatch leak
no help leak"
}
