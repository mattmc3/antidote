#!/usr/bin/env bats
# Unit tests for the _antidote completion helper functions.
# Runs them in plain zsh with compsys stubbed (see helpers/comp_stub.zsh).
# The _arguments specs themselves need a live shell to exercise; see
# docs/.completion-testing-notes.md for why that is not automated.

setup() {
  cd "$BATS_TEST_DIRNAME/../.."
  STUB=tests/bats/helpers/comp_stub.zsh
}

@test "_antidote parses cleanly" {
  run zsh -n functions/_antidote
  [ "$status" -eq 0 ]
}

@test "_antidote_subcommands parses commands from antidote --help" {
  run zsh -f "$STUB" _antidote_subcommands
  [ "$status" -eq 0 ]
  [[ "$output" == *"bundle:Clone bundle(s) and generate the static load script"* ]]
  [[ "$output" == *"install:Clone a new bundle and add it to your plugins file"* ]]
  [[ "$output" == *"load:Statically source all bundles from the plugins file"* ]]
}

@test "_antidote_subcommands ignores non-command help text" {
  run zsh -f "$STUB" _antidote_subcommands
  [[ "$output" != *"usage:"* ]]
}

@test "_antidote_installed_bundles reduces URLs to owner/repo" {
  run zsh -f "$STUB" _antidote_installed_bundles
  [ "$status" -eq 0 ]
  [[ "$output" == *"foo/bar"* ]]
  [[ "$output" == *"group/repo"* ]]
  [[ "$output" != *"https"* ]]
}

@test "_antidote_bundle_kinds lists every supported kind" {
  run zsh -f "$STUB" _antidote_bundle_kinds
  [ "$status" -eq 0 ]
  for kind in autoload clone defer fpath path zsh; do
    [[ "$output" == *"$kind"* ]]
  done
}
