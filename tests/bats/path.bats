#!/usr/bin/env bats
# antidote path tests (ported from tests/test_cmd_path.md)

load helpers/common

setup() {
  antidote_common_setup
  antidote_test_home
  antidote_clone_fixtures
}

@test "path prints the path to a bundle" {
  run antidote path foo/bar
  [ "$status" -eq 0 ]
  expect "$AHOME/fakegitsite.com/foo/bar"
}

@test "path fails on missing bundles" {
  run antidote path bar/foo
  [ "$status" -eq 1 ]
  expect "antidote: error: bar/foo does not exist in cloned paths"
}

@test "path accepts piped input from list" {
  output=$(antidote list | antidote path | sort)
  expect "$AHOME/fakegitsite.com/bar/baz
$AHOME/fakegitsite.com/foo/bar
$AHOME/fakegitsite.com/foo/baz
$AHOME/fakegitsite.com/foo/qux
$AHOME/fakegitsite.com/getantidote/zsh-defer
$AHOME/fakegitsite.com/ohmy/ohmy"
}

@test "path expands vars" {
  EXTRA_ENV="ZSH_CUSTOM=$ZDOTDIR/custom"
  run antidote path '$ZSH_CUSTOM/plugins/myplugin'
  expect "$ZDOTDIR/custom/plugins/myplugin"
}
