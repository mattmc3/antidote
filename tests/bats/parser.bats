#!/usr/bin/env bats
# antidote bundle_parser tests.
# The bundle parser takes the antidote bundle format and populates a
# _parsed_bundles[i,key] matrix with metadata in
# _parsed_bundles[__count__], parsed once.

load helpers/common

setup() { antidote_common_setup; }

# Each session defines the bundle_parser shorthand, plus val, which
# pairs input and parsed value so assertion failures name the exact
# case: "<bundle> [<key>] -> <value>".
parser_session() {
  SESSION_PRELUDE='function bundle_parser() { antidote __private__ bundle_parser_serialize "$@"; }
function val() { print -r -- "$1 [$2] -> $(print -r -- "$1" | bundle_parser | bundle_val "$2")" }' \
    run_session
}

@test "parser handles empty and comment-only input" {
  parser_session <<'EOS'
eval "$(echo | bundle_parser)"; print "empty count: $_parsed_bundles[__count__]"
eval "$(echo '# This is a full line comment' | bundle_parser)"; print "comment count: $_parsed_bundles[__count__]"
EOS
  assert_line "empty count: 0"
  assert_line "comment count: 0"
}

@test "parser matrix for a repo" {
  parser_session <<'EOS'
eval "$(echo 'foo/bar' | bundle_parser)"
print "count: $_parsed_bundles[__count__]"
print "bundle: $_parsed_bundles[1,__bundle__]"
print "type: $_parsed_bundles[1,__type__]"
EOS
  assert_line "count: 1"
  assert_line "bundle: foo/bar"
  assert_line "type: repo"
}

@test "parser matrix for multiple bundles" {
  parser_session <<'EOS'
eval "$(printf 'foo/bar\nbar/baz kind:defer\n' | bundle_parser)"
print "count: $_parsed_bundles[__count__]"
print "bundle 1: $_parsed_bundles[1,__bundle__]"
print "bundle 2: $_parsed_bundles[2,__bundle__]"
print "kind 2: $_parsed_bundles[2,kind]"
EOS
  assert_line "count: 2"
  assert_line "bundle 1: foo/bar"
  assert_line "bundle 2: bar/baz"
  assert_line "kind 2: defer"
}

@test "parser matrix for annotations" {
  parser_session <<'EOS'
eval "$(echo 'foo/bar branch:main kind:zsh' | bundle_parser)"
print "branch: $_parsed_bundles[1,branch]"
print "kind: $_parsed_bundles[1,kind]"
EOS
  assert_line "branch: main"
  assert_line "kind: zsh"
}

@test "parser tracks lineno through comments and blanks" {
  parser_session <<'EOS'
eval "$(printf '# comment\n\nfoo/bar\n' | bundle_parser)"
print "lineno: $_parsed_bundles[1,__lineno__]"
EOS
  assert_line "lineno: 3"
}

@test "parsed repo matrix rows" {
  parser_session <<<"echo 'foo/bar' | bundle_parser | print_parsed_bundle"
  expect '__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar'
}

@test "parsed repo matrix rows with escaped path-style" {
  parser_session <<'EOS'
zstyle ':antidote:bundle' path-style escaped
echo 'foo/bar' | bundle_parser | print_parsed_bundle
EOS
  expect '__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-fakegitsite.com-SLASH-foo-SLASH-bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar'
}

@test "parsed path bundle matrix rows" {
  parser_session <<<"echo '\$ZSH_CUSTOM/foo' | bundle_parser | print_parsed_bundle"
  expect '__bundle__  : $ZSH_CUSTOM/foo
__type__    : path'
}

@test "parsed jibberish flags errors" {
  parser_session <<'EOS'
echo 'a b c d:e:f' | bundle_parser | print_parsed_bundle
echo 'foo bar:baz' | bundle_parser | print_parsed_bundle
EOS
  expect "__bundle__  : a
__error__   : error: Expecting 'key:value' form for annotation 'c'.
__severity__: error
__type__    : using_subplugin
d           : e:f
__bundle__  : foo
__error__   : invalid bundle 'foo'. Are you missing a 'using:' directive?
__severity__: error
__type__    : using_subplugin
bar         : baz"
}

@test "parsed matrix with every annotation" {
  parser_session <<'EOS'
echo 'foo/bar branch:baz kind:zsh path:plugins/baz pre:precmd post:"post cmd"' | bundle_parser | print_parsed_bundle
EOS
  expect '__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar
branch      : baz
kind        : zsh
path        : plugins/baz
post        : post cmd
pre         : precmd'
}

@test "__type__ classification for many bundle forms" {
  parser_session <<'EOS'
val 'foo/bar' __type__
val 'https://github.com/foo/bar' __type__
val 'git@bitbucket.org:foo/bar' __type__
val '$foo/bar' __type__
val '$foo/bar/baz.zsh' __type__
val '~foo/bar' __type__
val '~/foo' __type__
val './foo.zsh' __type__
val '../foo.zsh' __type__
val 'foo/bar/' __type__
val 'foo:bar' __type__
val 'bad@gitsite.com/foo/bar' __type__
val 'http:/badsite.com/foo/bar' __type__
val 'https://gitlab.com/group/subgroup/repo' __type__
val 'https://gist.github.com/abc123def456' __type__
EOS
  assert_line 'foo/bar [__type__] -> repo'
  assert_line 'https://github.com/foo/bar [__type__] -> url'
  assert_line 'git@bitbucket.org:foo/bar [__type__] -> ssh_url'
  assert_line '$foo/bar [__type__] -> path'
  assert_line '$foo/bar/baz.zsh [__type__] -> path'
  assert_line '~foo/bar [__type__] -> path'
  assert_line '~/foo [__type__] -> path'
  assert_line './foo.zsh [__type__] -> path'
  assert_line '../foo.zsh [__type__] -> path'
  assert_line 'foo/bar/ [__type__] -> ?'
  assert_line 'foo:bar [__type__] -> ?'
  assert_line 'bad@gitsite.com/foo/bar [__type__] -> ?'
  assert_line 'http:/badsite.com/foo/bar [__type__] -> ?'
  assert_line 'https://gitlab.com/group/subgroup/repo [__type__] -> url'
  assert_line 'https://gist.github.com/abc123def456 [__type__] -> url'
}

@test "invalid bundles emit an error" {
  parser_session <<'EOS'
echo 'foobar' | bundle_parser | print_parsed_bundle
echo 'foo/bar/baz' | bundle_parser | print_parsed_bundle
echo 'foo/bar/' | bundle_parser | print_parsed_bundle
EOS
  expect "__bundle__  : foobar
__error__   : invalid bundle 'foobar'. Are you missing a 'using:' directive?
__severity__: error
__type__    : using_subplugin
__bundle__  : foo/bar/baz
__error__   : invalid bundle 'foo/bar/baz'
__severity__: error
__type__    : ?
__bundle__  : foo/bar/
__error__   : invalid bundle 'foo/bar/'
__severity__: error
__type__    : ?"
}

@test "__url__ values" {
  parser_session <<'EOS'
val 'foo/bar' __url__
val 'https://github.com/foo/bar' __url__
val 'git@bitbucket.org:foo/bar' __url__
val '$foo/bar' __url__
val 'bad@gitsite.com/foo/bar' __url__
val 'https://gitlab.com/group/subgroup/repo' __url__
val 'https://gist.github.com/abc123def456' __url__
EOS
  assert_line 'foo/bar [__url__] -> https://fakegitsite.com/foo/bar'
  assert_line 'https://github.com/foo/bar [__url__] -> https://github.com/foo/bar'
  assert_line 'git@bitbucket.org:foo/bar [__url__] -> git@bitbucket.org:foo/bar'
  assert_line '$foo/bar [__url__] -> '
  assert_line 'bad@gitsite.com/foo/bar [__url__] -> '
  assert_line 'https://gitlab.com/group/subgroup/repo [__url__] -> https://gitlab.com/group/subgroup/repo'
  assert_line 'https://gist.github.com/abc123def456 [__url__] -> https://gist.github.com/abc123def456'
}

@test "__bundle__ preserves the original bundle text" {
  parser_session <<'EOS'
for b in 'foo/bar' 'https://github.com/foo/bar' 'git@bitbucket.org:foo/bar' \
         '$foo/bar' '$foo/bar/baz.zsh' '~foo/bar' '~/foo' './foo.zsh' \
         '../foo.zsh' 'foo/bar/' 'foo:bar' 'bad@gitsite.com/foo/bar' \
         'http:/typo.com/foo/bar' 'https://gitlab.com/group/subgroup/repo' \
         'https://gist.github.com/abc123def456'; do
  val "$b" __bundle__
done
EOS
  assert_line 'foo/bar [__bundle__] -> foo/bar'
  assert_line 'https://github.com/foo/bar [__bundle__] -> https://github.com/foo/bar'
  assert_line 'git@bitbucket.org:foo/bar [__bundle__] -> git@bitbucket.org:foo/bar'
  assert_line '$foo/bar [__bundle__] -> $foo/bar'
  assert_line '$foo/bar/baz.zsh [__bundle__] -> $foo/bar/baz.zsh'
  assert_line '~foo/bar [__bundle__] -> ~foo/bar'
  assert_line '~/foo [__bundle__] -> ~/foo'
  assert_line './foo.zsh [__bundle__] -> ./foo.zsh'
  assert_line '../foo.zsh [__bundle__] -> ../foo.zsh'
  assert_line 'foo/bar/ [__bundle__] -> foo/bar/'
  assert_line 'foo:bar [__bundle__] -> foo:bar'
  assert_line 'bad@gitsite.com/foo/bar [__bundle__] -> bad@gitsite.com/foo/bar'
  assert_line 'http:/typo.com/foo/bar [__bundle__] -> http:/typo.com/foo/bar'
  assert_line 'https://gitlab.com/group/subgroup/repo [__bundle__] -> https://gitlab.com/group/subgroup/repo'
  assert_line 'https://gist.github.com/abc123def456 [__bundle__] -> https://gist.github.com/abc123def456'
}

@test "pin annotation is parsed" {
  parser_session <<<"echo 'foo/bar pin:abc123' | bundle_parser | print_parsed_bundle"
  expect '__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar
pin         : abc123'
}

@test "pin with kind:clone" {
  parser_session <<'EOS'
echo 'foo/bar kind:clone pin:64642c5691051ba0d82f5bda60b745f6fd042325' | bundle_parser | print_parsed_bundle
EOS
  expect '__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar
kind        : clone
pin         : 64642c5691051ba0d82f5bda60b745f6fd042325'
}

@test "ssh url parsing" {
  parser_session <<'EOS'
val 'git@bitbucket.org:foo/bar.git' __type__
val 'git@bitbucket.org:foo/bar.git' __bundle__
val 'git@bitbucket.org:foo/bar' __short__
val 'git@bitbucket.org:foo/bar.git' __short__
EOS
  assert_line 'git@bitbucket.org:foo/bar.git [__type__] -> ssh_url'
  assert_line 'git@bitbucket.org:foo/bar.git [__bundle__] -> git@bitbucket.org:foo/bar.git'
  assert_line 'git@bitbucket.org:foo/bar [__short__] -> git@bitbucket.org:foo/bar'
  assert_line 'git@bitbucket.org:foo/bar.git [__short__] -> git@bitbucket.org:foo/bar'
}

@test "ssh url __dir__" {
  parser_session <<<"echo 'git@fakegitsite.com:foo/qux' | bundle_parser | print_parsed_bundle"
  expect '__bundle__  : git@fakegitsite.com:foo/qux
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/qux
__short__   : git@fakegitsite.com:foo/qux
__type__    : ssh_url
__url__     : git@fakegitsite.com:foo/qux'
}

@test "conditional, autoload, and fpath-rule annotations" {
  parser_session <<'EOS'
val 'foo/bar conditional:is-macos' conditional
val 'foo/bar autoload:functions' autoload
val 'foo/bar fpath-rule:prepend' fpath-rule
EOS
  assert_line 'foo/bar conditional:is-macos [conditional] -> is-macos'
  assert_line 'foo/bar autoload:functions [autoload] -> functions'
  assert_line 'foo/bar fpath-rule:prepend [fpath-rule] -> prepend'
}

@test "multiline input parses all bundles" {
  parser_session <<'EOS'
printf 'foo/bar\nbar/baz kind:clone\n' | bundle_parser | bundle_val __bundle__
printf 'foo/bar\nbar/baz kind:clone\n' | bundle_parser | bundle_val kind
printf '# comment\n\nfoo/bar\n' | bundle_parser | bundle_val __lineno__
EOS
  expect 'foo/bar
bar/baz

clone
3'
}
