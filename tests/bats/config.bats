#!/usr/bin/env bats
# ANTIDOTE_CONFIG discovery tests. antidote.zsh sources
# ${ANTIDOTE_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/antidote/config.zsh}.
# The skeleton home ships ~/.config/antidote/config.zsh setting
# path-style short, so discovery is observable against the full-style
# default. ACONFIG="" makes the wrapper leave ANTIDOTE_CONFIG unset.

load helpers/common

setup() {
  antidote_common_setup
  antidote_test_home
}

@test "explicit ANTIDOTE_CONFIG beats the default config file" {
  run antidote __private__ bundle_dir foo/bar
  assert_output "$AHOME/fakegitsite.com/foo/bar"
}

@test "config is discovered at ~/.config/antidote/config.zsh" {
  ACONFIG=""
  run antidote __private__ bundle_dir foo/bar
  assert_output "$AHOME/foo/bar"
}

@test "XDG_CONFIG_HOME relocates config discovery" {
  ACONFIG=""
  mkdir -p "$TESTHOME/.xdg/antidote"
  echo "zstyle ':antidote:bundle' path-style escaped" >"$TESTHOME/.xdg/antidote/config.zsh"
  EXTRA_ENV="XDG_CONFIG_HOME=$TESTHOME/.xdg"
  run antidote __private__ bundle_dir foo/bar
  assert_output "$AHOME/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar"
}

# antidote-setup sources the config into the parent and marks it, so a
# subprocess launched from that shell must not source it a second time.
@test "the config file is sourced once per shell, not per command" {
  SESSION_PRELUDE='export ANTIDOTE_CONFIG=$HOME/cfg.zsh
print -r -- "print -n x >>\$HOME/srccount" >$ANTIDOTE_CONFIG
rm -f $HOME/srccount
antidote-setup'
  run_session <<'EOS'
antidote home >/dev/null
antidote --version >/dev/null
echo "sourced: ${#$(<$HOME/srccount)}"
EOS
  assert_output "sourced: 1"
}

# Nothing marked it, so a standalone subprocess still reads it itself.
@test "an unmarked subprocess sources the config itself" {
  SESSION_PRELUDE='export ANTIDOTE_CONFIG=$HOME/cfg.zsh
print -r -- "print -n x >>\$HOME/srccount" >$ANTIDOTE_CONFIG
rm -f $HOME/srccount'
  run_session <<'EOS'
zstyle -d ':antidote:config' sourced
antidote-zsh home >/dev/null
echo "sourced: ${#$(<$HOME/srccount)}"
EOS
  assert_output "sourced: 1"
}

@test "a missing config file is tolerated" {
  ACONFIG=""
  rm "$TESTHOME/.config/antidote/config.zsh"
  run antidote __private__ bundle_dir foo/bar
  assert_success
  assert_output "$AHOME/github.com/foo/bar"
}

@test "diagnostics reports the explicit config path" {
  run antidote --diagnostics
  assert_line --regexp "^ +config: +${ACONFIG}\$"
}

@test "diagnostics reports the discovered config path" {
  ACONFIG=""
  run antidote --diagnostics
  assert_line --regexp "^ +config: +${TESTHOME}/.config/antidote/config.zsh\$"
}

@test "diagnostics flags a config path with no file" {
  ACONFIG="$TESTHOME/.config/antidote/nope.zsh"
  run antidote --diagnostics
  assert_line --regexp "^ +config: +${ACONFIG} \(not found\)\$"
}
