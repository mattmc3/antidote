#!/usr/bin/env bats
# antidote end-to-end tests (ported from tests/test_antidote.md):
# version/help/home plus the bundle behaviors that only show up end to
# end (clone resolution, branches, path-style). The per-kind and
# per-annotation script output matrix lives in script.bats.

load helpers/common

setup() {
  antidote_common_setup
  antidote_test_home
}

@test "version prints a sha from a git checkout" {
  run antidote --version
  assert_success
  assert_output --regexp '^antidote version [0-9]+\.[0-9]+\.[0-9]+ \([a-f0-9]+\)$'
}

@test "version respects the show-sha test zstyle" {
  ZSTYLES="zstyle ':antidote:test:version' show-sha off"
  run antidote --version
  assert_output "antidote version $EXPECTED_VERSION"
}

@test "help shows full usage" {
  run antidote --help
  expect "antidote - the cure to slow zsh plugin management

usage: antidote [<flags>] <command> [<args> ...]

flags:
  -h, --help            Show context-sensitive help
  -v, --version         Show application version
      --diagnostics     Show antidote and system diagnostics

commands:
  bundle    Clone bundle(s) and generate the static load script
  install   Clone a new bundle and add it to your plugins file
  update    Update antidote and its cloned bundles
  purge     Remove a cloned bundle
  home      Print where antidote is cloning bundles
  list      List cloned bundles
  path      Print the path of a cloned bundle
  snapshot  Save, restore, or list bundle snapshots
  init      Initialize the shell for dynamic bundles"
}

@test "bundle clones a repo by short name" {
  run antidote bundle foo/bar
  expect '# antidote cloning foo/bar...
fpath+=( "$HOME/.cache/antidote/fakegitsite.com/foo/bar" )
source "$HOME/.cache/antidote/fakegitsite.com/foo/bar/bar.plugin.zsh"'
}

@test "bundle by url reuses an existing clone" {
  antidote bundle foo/bar &>/dev/null
  run antidote bundle https://fakegitsite.com/foo/bar
  expect 'fpath+=( "$HOME/.cache/antidote/fakegitsite.com/foo/bar" )
source "$HOME/.cache/antidote/fakegitsite.com/foo/bar/bar.plugin.zsh"'
}

@test "bundle clones a repo by ssh url" {
  run antidote bundle git@fakegitsite.com:foo/qux
  expect '# antidote cloning git@fakegitsite.com:foo/qux...
fpath+=( "$HOME/.cache/antidote/fakegitsite.com/foo/qux" )
source "$HOME/.cache/antidote/fakegitsite.com/foo/qux/qux.plugin.zsh"'
}

# The escaped path-style prints raw paths (print_path does not
# substitute $HOME in escaped mode).
@test "bundle honors escaped path-style" {
  ZSTYLES="zstyle ':antidote:bundle' path-style escaped"
  run antidote bundle foo/bar
  expect "# antidote cloning foo/bar...
fpath+=( \"$AHOME/https-COLON--SLASH--SLASH-fakegitsite.com-SLASH-foo-SLASH-bar\" )
source \"$AHOME/https-COLON--SLASH--SLASH-fakegitsite.com-SLASH-foo-SLASH-bar/bar.plugin.zsh\""
}

@test "bundle clones a specific branch with branch:<branch>" {
  antidote bundle 'foo/bar branch:dev' &>/dev/null
  run git -C "$AHOME/fakegitsite.com/foo/bar" rev-parse --abbrev-ref HEAD
  assert_output "dev"
}

@test "home prints the bundle cache dir" {
  run antidote home
  assert_output "$AHOME"
}
