#!/usr/bin/env bats
# antidote core tests (ported from tests/test_antidote_core.md).
# Tests for antidote's most basic functionality.

load helpers/common

setup() { antidote_common_setup; }

@test "fails gracefully when someone tries bash" {
  run_session <<'EOS'
bash -c "source $T_PRJDIR/antidote.zsh"
EOS
  expect "antidote: This script requires Zsh, not Bash"
}

@test "no args displays help and exits 2" {
  run_session <<'EOS'
echo $+functions[antidote]
antidote
echo "exit: $?"
EOS
  expected=$(cat <<'EOF'
1
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
exit: 2
EOF
)
  expect "$expected"
}

@test "help and version flags work" {
  run_session <<'EOS'
antidote -h >/dev/null && echo "-h ok"
antidote --help >/dev/null && echo "--help ok"
antidote --version | grep -qE 'antidote version [0-9]+\.[0-9]+\.[0-9]+ \([a-f0-9]+\)' && echo "version format ok"
antidote -v >/dev/null && echo "-v ok"
EOS
  expect "-h ok
--help ok
version format ok
-v ok"
}

@test "diagnostics shows system info" {
  run_session <<'EOS'
antidote --diagnostics | head -1
diag_has() { antidote --diagnostics | grep -qE "$2" && echo "$1 ok" }
diag_has version '^\s+version:\s+[0-9]+\.[0-9]+\.[0-9]+'
diag_has "snapshot dir" '^\s+snapshot dir:\s+.+'
diag_has snapshots '^\s+snapshots:\s+[0-9]+'
diag_has "zsh version" '^\s+zsh version:\s+.+'
diag_has "git version" '^\s+git version:\s+.+'
diag_has system '^\s+system:\s+.+'
antidote --diagnostics >/dev/null && echo "exit ok"
EOS
  expect "antidote:
version ok
snapshot dir ok
snapshots ok
zsh version ok
git version ok
system ok
exit ok"
}

@test "unrecognized options and commands fail with exit 1" {
  run_session <<'EOS'
antidote --foo 2>&1 >/dev/null | grep -qE '(bad option|command not found)' && echo "bad option reported"
antidote --foo &>/dev/null; echo "bad option exit: $?"
antidote foo 2>&1
echo "bad command exit: $?"
EOS
  expect "bad option reported
bad option exit: 1
antidote: command not found 'foo'
bad command exit: 1"
}
