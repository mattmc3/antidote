#!/usr/bin/env bats
# Per-bundle zcompile tests.
# Bundled paths under HOME print with a literal '$HOME' prefix.

load helpers/common

setup() {
  antidote_common_setup
  antidote_test_home
}

# bundle_zcompile reads dir lists back through a subshell, so a home
# with spaces has to split on lines, not words. One test per branch.
@test "bundle_zcompile compiles all bundles under a home with spaces" {
  AHOME="$TESTHOME/.cache/anti dote"
  antidote bundle foo/bar >/dev/null
  run antidote __private__ bundle_zcompile
  assert_success
  run find "$AHOME" -name '*.zwc'
  assert_output --partial '.zwc'
}

@test "bundle_zcompile compiles a named bundle under a home with spaces" {
  AHOME="$TESTHOME/.cache/anti dote"
  antidote bundle foo/bar >/dev/null
  run antidote __private__ bundle_zcompile 'foo/bar'
  assert_success
  run find "$AHOME" -name '*.zwc'
  assert_output --partial '.zwc'
}

@test "zcompile off leaves no zwc for a file bundle" {
  ZSTYLES="zstyle ':antidote:bundle:*' zcompile 'no'"
  run antidote bundle "$ZDOTDIR/custom/lib/lib1.zsh"
  assert_output 'source "$HOME/.zsh/custom/lib/lib1.zsh"'
  [ ! -e "$ZDOTDIR/custom/lib/lib1.zsh.zwc" ]
}

@test "zcompile off leaves no zwc for a theme bundle" {
  ZSTYLES="zstyle ':antidote:bundle:*' zcompile 'no'"
  run antidote bundle "$ZDOTDIR/custom/plugins/mytheme"
  assert_output 'fpath+=( "$HOME/.zsh/custom/plugins/mytheme" )
source "$HOME/.zsh/custom/plugins/mytheme/mytheme.zsh-theme"'
  [ ! -e "$ZDOTDIR/custom/plugins/mytheme/mytheme.zsh-theme.zwc" ]
}

@test "zcompile on compiles a lib file" {
  ZSTYLES="zstyle ':antidote:bundle:*' zcompile 'yes'"
  antidote bundle "$ZDOTDIR/custom/lib/lib2.zsh" >/dev/null
  [ -e "$ZDOTDIR/custom/lib/lib2.zsh.zwc" ]
}

@test "zcompile on compiles a plugin" {
  ZSTYLES="zstyle ':antidote:bundle:*' zcompile 'yes'"
  antidote bundle "$ZDOTDIR/custom/plugins/myplugin" >/dev/null
  [ -e "$ZDOTDIR/custom/plugins/myplugin/myplugin.plugin.zsh.zwc" ]
}

@test "zcompile on compiles a zsh-theme" {
  ZSTYLES="zstyle ':antidote:bundle:*' zcompile 'yes'"
  antidote bundle "$ZDOTDIR/custom/plugins/mytheme" >/dev/null
  [ -e "$ZDOTDIR/custom/plugins/mytheme/mytheme.zsh-theme.zwc" ]
}
