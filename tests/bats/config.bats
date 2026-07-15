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

@test "a missing config file is tolerated" {
  ACONFIG=""
  rm "$TESTHOME/.config/antidote/config.zsh"
  run antidote __private__ bundle_dir foo/bar
  assert_success
  assert_output "$AHOME/github.com/foo/bar"
}
