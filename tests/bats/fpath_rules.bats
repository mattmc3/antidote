#!/usr/bin/env bats
# antidote bundle fpath-rule:<rule> tests

load helpers/common

setup_file() { antidote_fixture_proto; }

setup() {
  antidote_common_setup
  antidote_test_home_cached
}

@test "fpath is appended to by default" {
  run antidote bundle foo/bar kind:fpath
  assert_output 'fpath+=( "$HOME/.cache/antidote/fakegitsite.com/foo/bar" )'
}

# fpath can be told to explicitly append, but it's unnecessary
@test "explicit fpath-rule:append works" {
  run antidote bundle foo/bar kind:zsh fpath-rule:append
  expect 'fpath+=( "$HOME/.cache/antidote/fakegitsite.com/foo/bar" )
source "$HOME/.cache/antidote/fakegitsite.com/foo/bar/bar.plugin.zsh"'
}

@test "fpath-rule:prepend prepends" {
  run antidote bundle foo/bar kind:fpath fpath-rule:prepend
  assert_output 'fpath=( "$HOME/.cache/antidote/fakegitsite.com/foo/bar" $fpath )'
}

@test "fpath rules can only be append or prepend" {
  run antidote bundle foo/bar kind:fpath fpath-rule:append
  assert_success
  run antidote bundle foo/bar kind:fpath fpath-rule:prepend
  assert_success
  run antidote bundle foo/bar kind:fpath fpath-rule:foo
  assert_failure 1
  assert_output "# antidote: error: unexpected fpath rule: 'foo'"
}

@test "fpath rules apply to kind:autoload" {
  run antidote bundle foo/baz path:baz kind:autoload fpath-rule:append
  expect 'fpath+=( "$HOME/.cache/antidote/fakegitsite.com/foo/baz/baz" )
builtin autoload -Uz "$HOME/.cache/antidote/fakegitsite.com/foo/baz/baz"/*(N.:t)'

  run antidote bundle foo/baz path:baz kind:autoload fpath-rule:prepend
  expect 'fpath=( "$HOME/.cache/antidote/fakegitsite.com/foo/baz/baz" $fpath )
builtin autoload -Uz "$HOME/.cache/antidote/fakegitsite.com/foo/baz/baz"/*(N.:t)'
}

@test "fpath rules apply to autoload:funcdir annotations" {
  run antidote bundle foo/baz autoload:baz fpath-rule:append
  expect 'fpath+=( "$HOME/.cache/antidote/fakegitsite.com/foo/baz/baz" )
builtin autoload -Uz "$HOME/.cache/antidote/fakegitsite.com/foo/baz/baz"/*(N.:t)
fpath+=( "$HOME/.cache/antidote/fakegitsite.com/foo/baz" )
source "$HOME/.cache/antidote/fakegitsite.com/foo/baz/baz.plugin.zsh"'

  run antidote bundle foo/baz autoload:baz fpath-rule:prepend
  expect 'fpath=( "$HOME/.cache/antidote/fakegitsite.com/foo/baz/baz" $fpath )
builtin autoload -Uz "$HOME/.cache/antidote/fakegitsite.com/foo/baz/baz"/*(N.:t)
fpath=( "$HOME/.cache/antidote/fakegitsite.com/foo/baz" $fpath )
source "$HOME/.cache/antidote/fakegitsite.com/foo/baz/baz.plugin.zsh"'
}

# fpath rules can be set globally with a zstyle:
#   zstyle ':antidote:fpath' rule 'prepend'
@test "global fpath rule zstyle" {
  ZSTYLES="zstyle ':antidote:fpath' rule prepend"

  run antidote bundle foo/bar
  expect 'fpath=( "$HOME/.cache/antidote/fakegitsite.com/foo/bar" $fpath )
source "$HOME/.cache/antidote/fakegitsite.com/foo/bar/bar.plugin.zsh"'

  run antidote bundle foo/bar kind:fpath
  assert_output 'fpath=( "$HOME/.cache/antidote/fakegitsite.com/foo/bar" $fpath )'

  run antidote bundle foo/baz path:baz kind:autoload
  expect 'fpath=( "$HOME/.cache/antidote/fakegitsite.com/foo/baz/baz" $fpath )
builtin autoload -Uz "$HOME/.cache/antidote/fakegitsite.com/foo/baz/baz"/*(N.:t)'
}

# It is NOT recommended, but explicit fpath-rules still beat the zstyle.
@test "explicit fpath-rule overrides the global zstyle" {
  ZSTYLES="zstyle ':antidote:fpath' rule prepend"

  run antidote bundle foo/bar fpath-rule:append
  expect 'fpath+=( "$HOME/.cache/antidote/fakegitsite.com/foo/bar" )
source "$HOME/.cache/antidote/fakegitsite.com/foo/bar/bar.plugin.zsh"'

  run antidote bundle foo/bar kind:fpath fpath-rule:append
  assert_output 'fpath+=( "$HOME/.cache/antidote/fakegitsite.com/foo/bar" )'

  run antidote bundle foo/baz path:baz kind:autoload fpath-rule:append
  expect 'fpath+=( "$HOME/.cache/antidote/fakegitsite.com/foo/baz/baz" )
builtin autoload -Uz "$HOME/.cache/antidote/fakegitsite.com/foo/baz/baz"/*(N.:t)'
}
