#!/usr/bin/env bats
# antidote core tests.
# Tests for antidote's most basic functionality.

load helpers/common

setup() { antidote_common_setup; antidote_test_home; }

@test "fails gracefully when someone tries bash" {
  run_session <<<'bash -c "source $T_PRJDIR/antidote.zsh"'
  assert_output "antidote: This script requires Zsh, not Bash"
}

@test "fails gracefully when someone tries plain sh" {
  run_session <<<'sh -c ". $T_PRJDIR/antidote.zsh"'
  assert_failure 1
  assert_output --partial "antidote: This script requires Zsh, not"
}

# zsh puts 'filecode' (not 'file') in ZSH_EVAL_CONTEXT when a script is
# loaded from its .zwc bytecode. Sourcing must still run setup instead
# of falling through to the CLI branch.
@test "sourcing works when compiled to zwc bytecode" {
  local libdir="$BATS_TEST_TMPDIR/zwc"
  mkdir -p "$libdir"
  cp "$PRJDIR/antidote.zsh" "$libdir"
  cp -R "$PRJDIR/functions" "$libdir"
  zsh -fc "zcompile '$libdir/antidote.zsh'"
  [ -f "$libdir/antidote.zsh.zwc" ]
  cat >"$BATS_TEST_TMPDIR/probe.zsh" <<EOS
source "$libdir/antidote.zsh"
echo "source exit: \$?"
echo "still alive: yes"
EOS
  run env HOME="$TESTHOME" zsh -f "$BATS_TEST_TMPDIR/probe.zsh"
  assert_success
  assert_output "source exit: 0
still alive: yes"
}

# functions/antidote exists so antidote can be autoloaded from fpath
# without sourcing antidote.zsh up front. The first call sources it.
@test "antidote can be lazy-loaded from its functions dir" {
  cat >"$BATS_TEST_TMPDIR/probe.zsh" <<EOS
fpath=( "$PRJDIR/functions" \$fpath )
autoload -Uz antidote
echo "dispatch before: \$+functions[antidote-dispatch]"
antidote --version
EOS
  run env HOME="$TESTHOME" zsh -f "$BATS_TEST_TMPDIR/probe.zsh"
  assert_success
  assert_line --index 0 "dispatch before: 0"
  assert_line --regexp '^antidote version [0-9]+\.[0-9]+\.[0-9]+ \([a-f0-9]+\)$'
}

# Homebrew et al install antidote behind a versioned symlink. Setup must
# record the link path, not its target, or a shell that started under the
# old version loses the functions dir the moment the target is replaced.
@test "sourcing through a symlinked install dir keeps the link path" {
  local libdir="$BATS_TEST_TMPDIR/kegs/1.0.0"
  mkdir -p "$libdir"
  cp "$PRJDIR/antidote.zsh" "$libdir"
  cp -R "$PRJDIR/functions" "$libdir"
  ln -s kegs/1.0.0 "$BATS_TEST_TMPDIR/opt"
  run env HOME="$TESTHOME" zsh -fc \
    "source '$BATS_TEST_TMPDIR/opt/antidote.zsh'; print -r -- \$fpath[1]"
  assert_success
  assert_output "$BATS_TEST_TMPDIR/opt/functions"
}

@test "commands still load after the symlink target is replaced" {
  local kegs="$BATS_TEST_TMPDIR/kegs"
  mkdir -p "$kegs/1.0.0"
  cp "$PRJDIR/antidote.zsh" "$kegs/1.0.0"
  cp -R "$PRJDIR/functions" "$kegs/1.0.0"
  cp -R "$kegs/1.0.0" "$kegs/2.0.0"
  ln -s kegs/1.0.0 "$BATS_TEST_TMPDIR/opt"
  cat >"$BATS_TEST_TMPDIR/probe.zsh" <<EOS
source "$BATS_TEST_TMPDIR/opt/antidote.zsh"
antidote --version >/dev/null   # load the dispatcher from 1.0.0
rm "$BATS_TEST_TMPDIR/opt"      # upgrade: repoint the link, drop the old keg
ln -s kegs/2.0.0 "$BATS_TEST_TMPDIR/opt"
rm -rf "$kegs/1.0.0"
antidote help >/dev/null
echo "help exit: \$?"
EOS
  run env HOME="$TESTHOME" PAGER=cat TERM=dumb zsh -f "$BATS_TEST_TMPDIR/probe.zsh"
  assert_success
  assert_output "help exit: 0"
}

@test "no args displays help and exits 2" {
  run_session <<'EOS'
echo "antidote fn defined: $+functions[antidote]"
antidote
EOS
  assert_failure 2
  assert_line --index 0 "antidote fn defined: 1"
  assert_output --partial "$(cat "$PRJDIR/tests/testdata/usage_dispatch.txt")"
}

@test "help and version flags work" {
  run_session <<'EOS'
antidote -h >/dev/null; echo "-h exit: $?"
antidote --help >/dev/null; echo "--help exit: $?"
antidote -v >/dev/null; echo "-v exit: $?"
antidote --version
EOS
  assert_line "-h exit: 0"
  assert_line "--help exit: 0"
  assert_line "-v exit: 0"
  assert_line --regexp '^antidote version [0-9]+\.[0-9]+\.[0-9]+ \([a-f0-9]+\)$'
}

@test "diagnostics shows system info" {
  run_session <<<'antidote --diagnostics'
  assert_success
  assert_line --index 0 "antidote:"
  assert_line --regexp '^[[:space:]]+version:[[:space:]]+[0-9]+\.[0-9]+\.[0-9]+'
  assert_line --regexp '^[[:space:]]+snapshot dir:[[:space:]]+.+'
  assert_line --regexp '^[[:space:]]+snapshots:[[:space:]]+[0-9]+'
  assert_line --regexp '^[[:space:]]+zsh version:[[:space:]]+.+'
  assert_line --regexp '^[[:space:]]+git version:[[:space:]]+.+'
  assert_line --regexp '^[[:space:]]+system:[[:space:]]+.+'
}

@test "unrecognized options and commands fail with exit 1" {
  run_session <<'EOS'
antidote --foo 2>&1 >/dev/null; echo "bad option exit: $?"
antidote foo 2>&1
EOS
  assert_failure 1
  assert_line --regexp 'bad option|command not found'
  assert_line "bad option exit: 1"
  assert_line "antidote: command not found 'foo'"
}

# The :antidote:test setopts style takes a list of extra shell options
# for antidote.zsh's own code. The probe function is defined in the
# config file, so it runs under whatever options the style requested.
@test "test setopts style applies extra shell options" {
  cat >"$TESTHOME/.config/antidote/setopts.zsh" <<'CFG'
zstyle ':antidote:test' setopts warn_create_global
leak_probe() { probe_global=1 }
CFG
  ACONFIG="$TESTHOME/.config/antidote/setopts.zsh"
  run antidote __private__ leak_probe
  assert_output --partial "created globally"
}

@test "no test setopts style means no extra shell options" {
  cat >"$TESTHOME/.config/antidote/setopts.zsh" <<'CFG'
leak_probe() { probe_global=1 }
CFG
  ACONFIG="$TESTHOME/.config/antidote/setopts.zsh"
  run antidote __private__ leak_probe
  refute_output --partial "created globally"
}

@test "diagnostics reports the git version via the git cmd zstyle" {
  cat >"$TESTHOME/fakegit" <<'STUB'
#!/bin/sh
echo "fakegit version 9.9.9"
STUB
  chmod +x "$TESTHOME/fakegit"
  ZSTYLES="zstyle ':antidote:git' cmd $TESTHOME/fakegit"
  run antidote --diagnostics
  assert_line --regexp '^ +git version: +fakegit version 9\.9\.9$'
}

@test "diagnostics lists the zstyles in effect" {
  ZSTYLES="zstyle ':antidote:git' site zstyle-probe.example"
  run antidote --diagnostics
  assert_output --partial "zstyles:"
  assert_output --partial "zstyle-probe.example"
}

# Runtime state that antidote probes for itself must not be settable from
# the environment. The probe function is defined in the config file so it
# runs inside antidote.zsh with the real globals in scope.
@test "an exported color flag cannot force color on" {
  cat >"$TESTHOME/.config/antidote/probe.zsh" <<'CFG'
color_probe() { setup_color; print -r -- "color=[$_ANTIDOTE_COLOR]" }
CFG
  ACONFIG="$TESTHOME/.config/antidote/probe.zsh"
  EXTRA_ENV="_ANTIDOTE_COLOR=true"
  run antidote __private__ color_probe
  assert_output "color=[]"
}

# Color comes straight from $fg and $reset_color, and reset_color is
# a scalar, so it can arrive from the environment. It must still blank.
@test "an exported reset_color cannot force color on" {
  cat >"$TESTHOME/.config/antidote/probe.zsh" <<'CFG'
reset_probe() { setup_color; print -r -- "reset=[$reset_color] blue=[$fg[blue]]" }
CFG
  ACONFIG="$TESTHOME/.config/antidote/probe.zsh"
  EXTRA_ENV="reset_color=$'\E[0m'"
  run antidote __private__ reset_probe
  assert_output "reset=[] blue=[]"
}

@test "an exported bat command cannot survive a failed bat probe" {
  cat >"$TESTHOME/.config/antidote/probe.zsh" <<'CFG'
bat_probe() { setup_color; setup_bat; print -r -- "bat=[$_ANTIDOTE_BAT_CMD]" }
CFG
  ACONFIG="$TESTHOME/.config/antidote/probe.zsh"
  EXTRA_ENV="_ANTIDOTE_BAT_CMD=/nonexistent/bat"
  run antidote __private__ bat_probe
  assert_output "bat=[]"
}

# fzf opts get their default at init like every other setting, so the
# value does not depend on whether snapshot_pick happened to run.
@test "fzf opts have their default before any picker runs" {
  cat >"$TESTHOME/.config/antidote/probe.zsh" <<'CFG'
fzf_probe() { print -r -- "[$_ANTIDOTE_FZF_OPTS]" }
CFG
  ACONFIG="$TESTHOME/.config/antidote/probe.zsh"
  run antidote __private__ fzf_probe
  assert_output "[--border=top --preview-window=right:75%]"
}

@test "the fzf opts zstyle overrides the default" {
  cat >"$TESTHOME/.config/antidote/probe.zsh" <<'CFG'
zstyle ':antidote:fzf' opts '--height=40%'
fzf_probe() { print -r -- "[$_ANTIDOTE_FZF_OPTS]" }
CFG
  ACONFIG="$TESTHOME/.config/antidote/probe.zsh"
  run antidote __private__ fzf_probe
  assert_output "[--height=40%]"
}
