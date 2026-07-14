#!/usr/bin/env bats
# antidote list tests (ported from tests/test_cmd_list.md).
# The full 6-bundle listings are the command's output contract, so
# whole-output compares are intentional.

load helpers/common

BARBAZ_SHA=1aa9550512f5606c5c23b11f5a9ad660d6c10fb4

setup() {
  antidote_common_setup
  antidote_test_home
  antidote_clone_fixtures
}

@test "list reports when there are no bundles" {
  rm -rf "$AHOME" && mkdir -p "$AHOME"
  run antidote list
  assert_output "antidote: list: no bundles found in '\$HOME/.cache/antidote'"
}

@test "list default shows path and url, tab separated" {
  run antidote list
  expect "$AHOME/fakegitsite.com/bar/baz	https://fakegitsite.com/bar/baz
$AHOME/fakegitsite.com/foo/bar	https://fakegitsite.com/foo/bar
$AHOME/fakegitsite.com/foo/baz	https://fakegitsite.com/foo/baz
$AHOME/fakegitsite.com/foo/qux	git@fakegitsite.com:foo/qux
$AHOME/fakegitsite.com/getantidote/zsh-defer	https://fakegitsite.com/getantidote/zsh-defer
$AHOME/fakegitsite.com/ohmy/ohmy	https://fakegitsite.com/ohmy/ohmy"
}

@test "list --url shows urls only" {
  run antidote list --url
  expect "git@fakegitsite.com:foo/qux
https://fakegitsite.com/bar/baz
https://fakegitsite.com/foo/bar
https://fakegitsite.com/foo/baz
https://fakegitsite.com/getantidote/zsh-defer
https://fakegitsite.com/ohmy/ohmy"
  run antidote list -u
  [ "${#lines[@]}" -eq 6 ]
}

@test "list --dirs shows directories only" {
  run antidote list --dirs
  expect "$AHOME/fakegitsite.com/bar/baz
$AHOME/fakegitsite.com/foo/bar
$AHOME/fakegitsite.com/foo/baz
$AHOME/fakegitsite.com/foo/qux
$AHOME/fakegitsite.com/getantidote/zsh-defer
$AHOME/fakegitsite.com/ohmy/ohmy"
  run antidote list -d
  [ "${#lines[@]}" -eq 6 ]
}

@test "list --long shows repo, path, url, and sha" {
  run antidote list --long
  assert_line --index 0 "Repo:   bar/baz"
  assert_line --index 1 'Path:   $HOME/.cache/antidote/fakegitsite.com/bar/baz'
  assert_line --index 2 "URL:    https://fakegitsite.com/bar/baz"
  assert_line --index 3 "SHA:    $BARBAZ_SHA"
}

@test "list --long shows full SSH URLs and no Pinned line when unpinned" {
  run antidote list --long
  assert_line "Repo:   git@fakegitsite.com:foo/qux"
  refute_output --partial "Pinned:"
}

@test "list --jsonl emits one valid json object per bundle" {
  run antidote list --jsonl
  [ "${#lines[@]}" -eq 6 ]
  assert_line "{\"url\":\"https://fakegitsite.com/bar/baz\",\"repo\":\"bar/baz\",\"path\":\"$AHOME/fakegitsite.com/bar/baz\",\"sha\":\"$BARBAZ_SHA\"}"
  refute_output --partial '"pin"'
}

@test "list --jsonl parses with jq" {
  output=$(antidote list --jsonl | jq -r '.repo' | sort | paste -sd, -)
  assert_output "bar/baz,foo/bar,foo/baz,getantidote/zsh-defer,git@fakegitsite.com:foo/qux,ohmy/ohmy"
}

# Quotes and backslashes in values must be JSON-escaped so every line
# stays valid JSON.
@test "list --jsonl escapes quotes and backslashes" {
  git -C "$AHOME/fakegitsite.com/foo/bar" config remote.origin.url 'https://fakegitsite.com/foo/"bar\baz"'
  run antidote list --jsonl
  assert_output --partial '"url":"https://fakegitsite.com/foo/\"bar\\baz\""'
}
