#!/usr/bin/env bats
# Helper function tests (ported from tests/test_helpers.md). Each case
# runs antidote.zsh as a subprocess via `antidote __private__ <fn>` with
# an isolated HOME; no shell session state is carried between cases.

load lib/bats-support/load
load lib/bats-assert/load

setup() {
  cd "$BATS_TEST_DIRNAME/../.."
  PRJDIR=$PWD
  # Resolve symlinks (macOS /var/folders -> /private/var) so subprocess
  # path prefix checks against $HOME hold.
  mkdir -p "$BATS_TEST_TMPDIR/home"
  TESTHOME="$(cd "$BATS_TEST_TMPDIR/home" && pwd -P)"
  ZDOTDIR="$TESTHOME/.zsh"
  AHOME="$TESTHOME/.cache/antidote"
  mkdir -p "$ZDOTDIR" "$AHOME"
  ZSTYLES="zstyle ':antidote:git' site fakegitsite.com"
  EXTRA_ENV=""
}

# Run `antidote __private__ <fn> [args...]` in the isolated test home.
__private__() {
  ( cd "$TESTHOME" && env \
      -u XDG_CACHE_HOME -u XDG_DATA_HOME -u XDG_CONFIG_HOME \
      HOME="$TESTHOME" ZDOTDIR="$ZDOTDIR" T_PRJDIR="$PRJDIR" \
      ANTIDOTE_HOME="$AHOME" ANTIDOTE_CONFIG=/dev/null \
      ANTIDOTE_ZSTYLES="$ZSTYLES" $EXTRA_ENV \
      zsh "$PRJDIR/antidote.zsh" __private__ "$@" )
}

# check <expected-output> <fn> [args...] - run and compare, with a
# readable failure message.
check() {
  local expected=$1; shift
  run __private__ "$@"
  if [ "$output" != "$expected" ]; then
    echo "cmd:      antidote __private__ $*"
    echo "expected: $expected"
    echo "got:      $output"
    return 1
  fi
}

# Appease my paranoia and ensure you can't remove a path you shouldn't
# be able to.
@test "del blocks removal outside HOME and tempdir" {
  run __private__ del -- /foo/bar
  assert_failure
  assert_output --partial "Blocked attempt to rm path: '/foo/bar'."
}

@test "bundle_type classifies files, dirs, and paths" {
  touch "$TESTHOME/.zshenv" "$ZDOTDIR/.zsh_plugins.txt"
  check file "bundle_type" "$PRJDIR/antidote.zsh"
  check dir "bundle_type" "$PRJDIR/functions"
  check file "bundle_type" '$T_PRJDIR/antidote.zsh'
  check dir "bundle_type" '$T_PRJDIR/functions'
  check path "bundle_type" '$ZDOTDIR/foo'
  check file "bundle_type" '$ZDOTDIR/.zsh_plugins.txt'
  check file "bundle_type" '~/.zshenv'
  check path "bundle_type" '~/null'
  check path "bundle_type" '~/foo/bar'
  check path "bundle_type" '$foo/bar'
  check path "bundle_type" /foo/bar
  check path "bundle_type" /foobar
}

@test "bundle_type classifies urls and repos" {
  check ssh_url "bundle_type" 'git@fakegitsite.com:foo/bar.git'
  check url "bundle_type" 'https://fakegitsite.com/foo/bar'
  check url "bundle_type" 'https://gist.github.com/someuser/abc123def456'
  check url "bundle_type" 'https://gist.github.com/someuser/abc123def456.git'
  check url "bundle_type" 'https://gitlab.com/group/subgroup/repo'
  check url "bundle_type" 'https://github.com'
  check url "bundle_type" 'https://github.com.git'
  check repo "bundle_type" foo/bar
  check repo "bundle_type" bar/baz.git
}

@test "bundle_type flags invalid, empty, and bare-word bundles" {
  check '?' "bundle_type" 'https:/typo.com/foo/bar.git'
  check '?' "bundle_type" foobar/
  check '?' "bundle_type" foo/bar/baz
  check '?' "bundle_type" 'foo bar baz'
  check empty "bundle_type" ''
  check empty "bundle_type" '    '
  check using_subplugin "bundle_type" foobar
  check using_subplugin "bundle_type" foo bar baz
}

@test "bundle_name shortens urls and prettifies paths" {
  # Paths under HOME print with a literal '$HOME' prefix.
  check '$HOME/.zsh/custom/lib/lib1.zsh' "bundle_name" "$TESTHOME/.zsh/custom/lib/lib1.zsh"
  check '$HOME/.zsh/plugins/myplugin' "bundle_name" "$TESTHOME/.zsh/plugins/myplugin"
  check 'git@fakegitsite.com:foo/bar' "bundle_name" 'git@fakegitsite.com:foo/bar.git'
  check foo/bar "bundle_name" 'https://fakegitsite.com/foo/bar'
  check someuser/abc123def456 "bundle_name" 'https://gist.github.com/someuser/abc123def456.git'
  check subgroup/repo "bundle_name" 'https://gitlab.com/group/subgroup/repo'
  check 'https:/bad.com/foo/bar.git' "bundle_name" 'https:/bad.com/foo/bar.git'
  check '' "bundle_name" ''
  check /foo/bar "bundle_name" /foo/bar
  check /foobar "bundle_name" /foobar
  check foobar/ "bundle_name" foobar/
  check '$HOME/foo/bar' "bundle_name" '~/foo/bar'
  check '$foo/bar' "bundle_name" '$foo/bar'
  check foo/bar "bundle_name" foo/bar
  check bar/baz.git "bundle_name" bar/baz.git
  check foo/bar/baz "bundle_name" foo/bar/baz
  check foobar "bundle_name" foobar
  check foo "bundle_name" foo bar baz
  check 'foo bar baz' "bundle_name" 'foo bar baz'
}

@test "__bundle_dir_by_style computes each path style" {
  check "$AHOME/https-COLON--SLASH--SLASH-fakegitsite.com-SLASH-foo-SLASH-bar" \
    "__bundle_dir_by_style" 'https://fakegitsite.com/foo/bar' escaped
  check "$AHOME/fakegitsite.com/foo/bar" \
    "__bundle_dir_by_style" 'https://fakegitsite.com/foo/bar' full
  check "$AHOME/foo/bar" \
    "__bundle_dir_by_style" 'https://fakegitsite.com/foo/bar' short
  check "$AHOME/git-AT-fakegitsite.com-COLON-foo-SLASH-bar" \
    "__bundle_dir_by_style" 'git@fakegitsite.com:foo/bar' escaped
  check "$AHOME/fakegitsite.com/foo/bar" \
    "__bundle_dir_by_style" 'git@fakegitsite.com:foo/bar' full
  check "$AHOME/foo/bar" \
    "__bundle_dir_by_style" 'git@fakegitsite.com:foo/bar' short
}

@test "bundle_dir honors path-style escaped" {
  ZSTYLES="$ZSTYLES
zstyle ':antidote:bundle' path-style escaped"
  check "$AHOME/https-COLON--SLASH--SLASH-fakegitsite.com-SLASH-foo-SLASH-bar" "bundle_dir" foo/bar
  check "$AHOME/https-COLON--SLASH--SLASH-fakegitsite.com-SLASH-foo-SLASH-bar" "bundle_dir" https://fakegitsite.com/foo/bar
  check "$AHOME/https-COLON--SLASH--SLASH-fakegitsite.com-SLASH-foo-SLASH-bar" "bundle_dir" https://fakegitsite.com/foo/bar.git
  check "$AHOME/git-AT-fakegitsite.com-COLON-foo-SLASH-bar" "bundle_dir" git@fakegitsite.com:foo/bar.git
  check "$AHOME/https-COLON--SLASH--SLASH-gist.github.com-SLASH-someuser-SLASH-abc123def456" \
    "bundle_dir" https://gist.github.com/someuser/abc123def456.git
  check "$TESTHOME/foo/bar" "bundle_dir" "$TESTHOME/foo/bar"
  check "$ZDOTDIR/bar/baz" "bundle_dir" "$ZDOTDIR/bar/baz"
}

@test "bundle_dir honors path-style short" {
  ZSTYLES="$ZSTYLES
zstyle ':antidote:bundle' path-style short"
  check "$AHOME/foo/bar" "bundle_dir" foo/bar
  check "$AHOME/bar/baz" "bundle_dir" https://fakegitsite.com/bar/baz
  check "$AHOME/foo/bar/baz/qux" "bundle_dir" https://fakegitsite.com/foo/bar/baz/qux
  check "$AHOME/foo/qux" "bundle_dir" git@fakegitsite.com:foo/qux.git
  check "$AHOME/someuser/abc123def456" "bundle_dir" https://gist.github.com/someuser/abc123def456.git
}

@test "bundle_dir honors path-style full" {
  ZSTYLES="$ZSTYLES
zstyle ':antidote:bundle' path-style full"
  check "$AHOME/fakegitsite.com/foo/bar" "bundle_dir" foo/bar
  check "$AHOME/fakegitsite.com/bar/baz" "bundle_dir" https://fakegitsite.com/bar/baz
  check "$AHOME/fakegitsite.com/foo/qux" "bundle_dir" git@fakegitsite.com:foo/qux.git
  check "$AHOME/gist.github.com/someuser/abc123def456" "bundle_dir" https://gist.github.com/someuser/abc123def456.git
  check "$AHOME/gitlab.com/group/subgroup/repo" "bundle_dir" https://gitlab.com/group/subgroup/repo
}

@test "bundle_dir honors legacy use-friendly-names" {
  ZSTYLES="$ZSTYLES
zstyle ':antidote:bundle' use-friendly-names on"
  check "$AHOME/foo/bar" "bundle_dir" foo/bar
  check "$AHOME/bar/baz" "bundle_dir" https://fakegitsite.com/bar/baz
  check "$AHOME/foo/bar/baz/qux" "bundle_dir" https://fakegitsite.com/foo/bar/baz/qux
  check "$AHOME/foo/qux" "bundle_dir" git@fakegitsite.com:foo/qux.git
}

@test "tourl expands short repos against the git site" {
  check https://fakegitsite.com/ohmyzsh/ohmyzsh "tourl" ohmyzsh/ohmyzsh
  check https://fakegitsite.com/sindresorhus/pure "tourl" sindresorhus/pure
  check https://fakegitsite.com/foo/bar "tourl" foo/bar
}

@test "tourl leaves proper URLs unchanged" {
  check https://github.com/ohmyzsh/ohmyzsh "tourl" https://github.com/ohmyzsh/ohmyzsh
  check http://github.com/ohmyzsh/ohmyzsh "tourl" http://github.com/ohmyzsh/ohmyzsh
  check ssh://github.com/ohmyzsh/ohmyzsh "tourl" ssh://github.com/ohmyzsh/ohmyzsh
  check git://github.com/ohmyzsh/ohmyzsh "tourl" git://github.com/ohmyzsh/ohmyzsh
  check ftp://github.com/ohmyzsh/ohmyzsh "tourl" ftp://github.com/ohmyzsh/ohmyzsh
  check git@github.com:sindresorhus/pure.git "tourl" git@github.com:sindresorhus/pure.git
}

@test "short_repo_name reduces to owner/repo" {
  check foo/bar "short_repo_name" foo/bar
  check foo/bar "short_repo_name" https://github.com/foo/bar
  check foo/bar "short_repo_name" https://github.com/foo/bar.git
  check git@github.com:foo/bar "short_repo_name" git@github.com:foo/bar.git
  check git@github.com:foo/bar "short_repo_name" git@github.com:foo/bar
  check nested/repo "short_repo_name" https://gitlab.com/deep/nested/repo
}

@test "get_cachedir picks the right dir per OS" {
  ZSTYLES="$ZSTYLES
zstyle ':antidote:test:env' OSTYPE linux-gnu"
  check "$TESTHOME/.cache" "get_cachedir"
  check "$TESTHOME/.cache/antidote" "get_cachedir" antidote
  ZSTYLES="zstyle ':antidote:test:env' OSTYPE darwin23.0"
  check "$TESTHOME/Library/Caches" "get_cachedir"
  check "$TESTHOME/Library/Caches/antidote" "get_cachedir" antidote
}

@test "get_cachedir honors XDG_CACHE_HOME" {
  ZSTYLES="$ZSTYLES
zstyle ':antidote:test:env' OSTYPE linux-gnu"
  EXTRA_ENV="XDG_CACHE_HOME=/tmp/xdg-cache"
  check /tmp/xdg-cache "get_cachedir"
  check /tmp/xdg-cache/antidote "get_cachedir" antidote
}

@test "get_datadir picks the right dir per OS" {
  ZSTYLES="$ZSTYLES
zstyle ':antidote:test:env' OSTYPE linux-gnu"
  check "$TESTHOME/.local/share" "get_datadir"
  check "$TESTHOME/.local/share/antidote" "get_datadir" antidote
  ZSTYLES="zstyle ':antidote:test:env' OSTYPE darwin23.0"
  check "$TESTHOME/Library/Application Support" "get_datadir"
  check "$TESTHOME/Library/Application Support/antidote" "get_datadir" antidote
}

@test "get_datadir honors XDG_DATA_HOME" {
  ZSTYLES="$ZSTYLES
zstyle ':antidote:test:env' OSTYPE linux-gnu"
  EXTRA_ENV="XDG_DATA_HOME=/tmp/xdg-data"
  check /tmp/xdg-data "get_datadir"
  check /tmp/xdg-data/antidote "get_datadir" antidote
}

@test "collect_input reads args, stdin, or nothing" {
  [ "$(echo foo/bar | __private__ collect_input)" = "foo/bar" ]
  [ "$(printf 'foo/bar\nbar/baz\nbaz/qux\n' | __private__ collect_input)" = $'foo/bar\nbar/baz\nbaz/qux' ]
  [ "$(__private__ collect_input 'foo/bar' </dev/null)" = "foo/bar" ]
  [ "$(__private__ collect_input $'foo/bar\nbar/baz' </dev/null)" = $'foo/bar\nbar/baz' ]
  [ "$(echo piped | __private__ collect_input args-win)" = "args-win" ]
  [ "$(__private__ collect_input </dev/null)" = "" ]
}
