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
  [ "$status" -eq 1 ]
  expect "antidote: error: required argument 'bundle' not provided, try --help"
}

@test "purging a missing bundle fails" {
  run antidote purge bar/foo
  [ "$status" -eq 1 ]
  expect "antidote: error: bar/foo does not exist at the expected location: $AHOME/fakegitsite.com/bar/foo"
}

@test "purge removes the bundle directory" {
  [ -d "$AHOME/fakegitsite.com/foo/bar" ]
  run antidote purge foo/bar
  [[ "$output" == *"Removed 'foo/bar'."* ]]
  [ ! -d "$AHOME/fakegitsite.com/foo/bar" ]
}

@test "purge comments out the bundle in the plugins file" {
  run antidote purge foo/bar
  [[ "$output" == *"Bundle 'foo/bar' was commented out in '$ZDOTDIR/.zsh_plugins.txt'."* ]]
  run diff "$ZDOTDIR/.zsh_plugins.txt" "$PRJDIR/tests/testdata/.zsh_plugins_purged.txt"
  [ "$status" -eq 0 ]
}

@test "purging a local path is not allowed" {
  run antidote purge "$AHOME"
  [ "$status" -eq 2 ]
  expect "antidote: error: '$AHOME' is not a repo and cannot be removed by antidote."
}

# When no bundlefile exists, purge still removes the bundle but doesn't
# mention commenting anything out.
@test "purge without a bundlefile still removes the bundle" {
  ZSTYLES="zstyle ':antidote:bundle' file /no/such/.zsh_plugins.txt"
  run antidote purge foo/baz
  expect "Removed 'foo/baz'."
}

@test "purge --all aborts when told no" {
  ZSTYLES="zstyle ':antidote:test:purge' answer 'n'"
  run antidote purge --all
  [ "$status" -eq 1 ]
  run antidote list --url
  [[ "$output" == *foo/bar* && "$output" == *ohmy/ohmy* ]]
}

@test "purge --all removes everything when told yes" {
  ZSTYLES="zstyle ':antidote:test:purge' answer 'y'"
  run antidote purge --all
  [[ "$output" == *"Antidote purge complete. Be sure to start a new Zsh session."* ]]
  [ ! -e "$AHOME" ]
}
