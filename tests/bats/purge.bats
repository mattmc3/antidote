#!/usr/bin/env bats
# antidote purge tests (ported from tests/test_cmd_purge.md)

load helpers/common

setup() {
  antidote_common_setup
  antidote_test_home
  antidote_clone_fixtures
}

@test "purge requires a bundle argument" {
  run antidote purge
  assert_failure 1
  assert_output "antidote: error: required argument 'bundle' not provided, try --help"
}

@test "purging a missing bundle fails" {
  run antidote purge bar/foo
  assert_failure 1
  assert_output "antidote: error: bar/foo does not exist at the expected location: $AHOME/fakegitsite.com/bar/foo"
}

@test "purge removes the bundle directory" {
  [ -d "$AHOME/fakegitsite.com/foo/bar" ]
  run antidote purge foo/bar
  assert_output --partial "Removed 'foo/bar'."
  [ ! -d "$AHOME/fakegitsite.com/foo/bar" ]
}

@test "purge comments out the bundle in the plugins file" {
  run antidote purge foo/bar
  assert_output --partial "Bundle 'foo/bar' was commented out in '$ZDOTDIR/.zsh_plugins.txt'."
  run diff "$ZDOTDIR/.zsh_plugins.txt" "$PRJDIR/tests/testdata/.zsh_plugins_purged.txt"
  assert_success
}

@test "purging a local path is not allowed" {
  run antidote purge "$AHOME"
  assert_failure 2
  assert_output "antidote: error: '$AHOME' is not a repo and cannot be removed by antidote."
}

# When no bundlefile exists, purge still removes the bundle but doesn't
# mention commenting anything out.
@test "purge without a bundlefile still removes the bundle" {
  ZSTYLES="zstyle ':antidote:bundle' file /no/such/.zsh_plugins.txt"
  run antidote purge foo/baz
  assert_output "Removed 'foo/baz'."
}

@test "purge --all aborts when told no" {
  ZSTYLES="zstyle ':antidote:test:purge' answer 'n'"
  run antidote purge --all
  assert_failure 1
  run antidote list --url
  assert_output --partial foo/bar
  assert_output --partial ohmy/ohmy
}

@test "purge --all removes everything when told yes" {
  ZSTYLES="zstyle ':antidote:test:purge' answer 'y'"
  run antidote purge --all
  assert_output --partial "Antidote purge complete. Be sure to start a new Zsh session."
  [ ! -e "$AHOME" ]
}
