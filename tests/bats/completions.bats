#!/usr/bin/env bats
# Unit tests for the _antidote completion helper functions.
# Runs them in plain zsh with compsys stubbed (see helpers/comp_stub.zsh).
# The _arguments specs themselves need a live shell to exercise; see
# docs/.completion-testing-notes.md for why that is not automated.

load lib/bats-support/load
load lib/bats-assert/load

setup() {
  cd "$BATS_TEST_DIRNAME/../.."
  STUB=tests/bats/helpers/comp_stub.zsh
}

@test "_antidote parses cleanly" {
  run zsh -n functions/_antidote
  assert_success
}

@test "_antidote_subcommands parses commands from antidote --help" {
  run zsh -f "$STUB" _antidote_subcommands
  assert_success
  assert_output --partial "bundle:Clone bundle(s) and generate the static load script"
  assert_output --partial "install:Clone a new bundle and add it to your plugins file"
  assert_output --partial "load:Statically source all bundles from the plugins file"
}

@test "_antidote_subcommands ignores non-command help text" {
  run zsh -f "$STUB" _antidote_subcommands
  refute_output --partial "usage:"
}

@test "_antidote_installed_bundles reduces URLs to owner/repo" {
  run zsh -f "$STUB" _antidote_installed_bundles
  assert_success
  assert_output --partial "foo/bar"
  assert_output --partial "group/repo"
  refute_output --partial "https"
}

@test "_antidote_bundle_kinds lists every supported kind" {
  run zsh -f "$STUB" _antidote_bundle_kinds
  assert_success
  for kind in autoload clone defer fpath path zsh; do
    assert_output --partial "$kind"
  done
}
