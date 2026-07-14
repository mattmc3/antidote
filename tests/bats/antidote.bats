#!/usr/bin/env bats
# antidote end-to-end bundle tests (ported from tests/test_antidote.md).
# Script-generation outputs compare whole blocks on purpose: the
# emitted script is the unit under test, and paths print with a literal
# '$HOME' prefix (print_path).

load helpers/common

setup() {
  antidote_common_setup
  antidote_test_home
}

@test "version prints a sha from a git checkout" {
  run antidote --version
  [[ "$output" =~ ^"antidote version "[0-9]+\.[0-9]+\.[0-9]+" ("[a-f0-9]+")"$ ]]
}

@test "version respects the show-sha test zstyle" {
  ZSTYLES="zstyle ':antidote:test:version' show-sha off"
  run antidote --version
  expect "antidote version $EXPECTED_VERSION"
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
  expect "dev"
}

@test "kind:zsh is the default load style" {
  antidote bundle foo/bar &>/dev/null
  run antidote bundle foo/bar kind:zsh
  expect 'fpath+=( "$HOME/.cache/antidote/fakegitsite.com/foo/bar" )
source "$HOME/.cache/antidote/fakegitsite.com/foo/bar/bar.plugin.zsh"'
}

@test "kind:path exports PATH" {
  antidote bundle foo/bar &>/dev/null
  run antidote bundle foo/bar kind:path
  expect 'export PATH="$HOME/.cache/antidote/fakegitsite.com/foo/bar:$PATH"'
}

@test "kind:fpath adds to fpath only" {
  antidote bundle foo/bar &>/dev/null
  run antidote bundle foo/bar kind:fpath
  expect 'fpath+=( "$HOME/.cache/antidote/fakegitsite.com/foo/bar" )'
}

@test "kind:clone clones without loading" {
  antidote bundle foo/bar &>/dev/null
  run antidote bundle foo/bar kind:clone
  expect ""
}

@test "kind:autoload autoloads a path" {
  antidote bundle foo/baz &>/dev/null
  run antidote bundle foo/baz kind:autoload path:functions
  expect 'fpath+=( "$HOME/.cache/antidote/fakegitsite.com/foo/baz/functions" )
builtin autoload -Uz $fpath[-1]/*(N.:t)'
}

@test "kind:defer wraps loading in zsh-defer" {
  antidote bundle foo/baz &>/dev/null
  antidote bundle getantidote/zsh-defer kind:clone &>/dev/null
  run antidote bundle foo/baz kind:defer
  expect 'if ! (( $+functions[zsh-defer] )); then
  fpath+=( "$HOME/.cache/antidote/fakegitsite.com/getantidote/zsh-defer" )
  source "$HOME/.cache/antidote/fakegitsite.com/getantidote/zsh-defer/zsh-defer.plugin.zsh"
fi
fpath+=( "$HOME/.cache/antidote/fakegitsite.com/foo/baz" )
zsh-defer source "$HOME/.cache/antidote/fakegitsite.com/foo/baz/baz.plugin.zsh"'
}

@test "path: loads a subplugin" {
  antidote bundle ohmy/ohmy kind:clone &>/dev/null
  run antidote bundle ohmy/ohmy path:plugins/docker
  expect 'fpath+=( "$HOME/.cache/antidote/fakegitsite.com/ohmy/ohmy/plugins/docker" )
source "$HOME/.cache/antidote/fakegitsite.com/ohmy/ohmy/plugins/docker/docker.plugin.zsh"'
}

@test "path: loads a whole lib directory" {
  antidote bundle ohmy/ohmy kind:clone &>/dev/null
  run antidote bundle ohmy/ohmy path:lib
  expect 'fpath+=( "$HOME/.cache/antidote/fakegitsite.com/ohmy/ohmy/lib" )
source "$HOME/.cache/antidote/fakegitsite.com/ohmy/ohmy/lib/lib1.zsh"
source "$HOME/.cache/antidote/fakegitsite.com/ohmy/ohmy/lib/lib2.zsh"
source "$HOME/.cache/antidote/fakegitsite.com/ohmy/ohmy/lib/lib3.zsh"'
}

@test "path: loads a specific file" {
  antidote bundle ohmy/ohmy kind:clone &>/dev/null
  run antidote bundle ohmy/ohmy path:custom/themes/pretty.zsh-theme
  expect 'source "$HOME/.cache/antidote/fakegitsite.com/ohmy/ohmy/custom/themes/pretty.zsh-theme"'
}

@test "conditional: wraps the bundle in if logic" {
  antidote bundle foo/bar &>/dev/null
  run antidote bundle foo/bar conditional:is-macos
  expect 'if is-macos; then
  fpath+=( "$HOME/.cache/antidote/fakegitsite.com/foo/bar" )
  source "$HOME/.cache/antidote/fakegitsite.com/foo/bar/bar.plugin.zsh"
fi'
}

@test "home prints the bundle cache dir" {
  run antidote home
  expect "$AHOME"
}
