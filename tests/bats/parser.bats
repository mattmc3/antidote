#!/usr/bin/env bats
# antidote bundle_parser tests (ported from tests/test_parser.md).
# The bundle parser takes the antidote bundle format and populates a
# _parsed_bundles[i,key] matrix with metadata in
# _parsed_bundles[__count__], parsed once.

load helpers/common

setup() { antidote_common_setup; }

# Each session defines the same shorthand the clitest file used.
parser_session() {
  SESSION_PRELUDE='function bundle_parser() { antidote __private__ bundle_parser_serialize "$@"; }' \
    run_session
}

@test "parser handles empty and comment-only input" {
  parser_session <<'EOS'
eval "$(echo | bundle_parser)"; print $_parsed_bundles[__count__]
eval "$(echo '# This is a full line comment' | bundle_parser)"; print $_parsed_bundles[__count__]
EOS
  expect "0
0"
}

@test "parser matrix for a repo" {
  parser_session <<'EOS'
eval "$(echo 'foo/bar' | bundle_parser)"
print $_parsed_bundles[__count__]
print $_parsed_bundles[1,__bundle__]
print $_parsed_bundles[1,__type__]
EOS
  expect "1
foo/bar
repo"
}

@test "parser matrix for multiple bundles" {
  parser_session <<'EOS'
eval "$(printf 'foo/bar\nbar/baz kind:defer\n' | bundle_parser)"
print $_parsed_bundles[__count__]
print $_parsed_bundles[1,__bundle__]
print $_parsed_bundles[2,__bundle__]
print $_parsed_bundles[2,kind]
EOS
  expect "2
foo/bar
bar/baz
defer"
}

@test "parser matrix for annotations" {
  parser_session <<'EOS'
eval "$(echo 'foo/bar branch:main kind:zsh' | bundle_parser)"
print $_parsed_bundles[1,branch]
print $_parsed_bundles[1,kind]
EOS
  expect "main
zsh"
}

@test "parser tracks lineno through comments and blanks" {
  parser_session <<'EOS'
eval "$(printf '# comment\n\nfoo/bar\n' | bundle_parser)"
print $_parsed_bundles[1,__lineno__]
EOS
  expect "3"
}

@test "parsed repo matrix rows" {
  parser_session <<'EOS'
echo 'foo/bar' | bundle_parser | print_parsed_bundle
EOS
  expected=$(cat <<'EOF'
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar
EOF
)
  expect "$expected"
}

@test "parsed repo matrix rows with escaped path-style" {
  parser_session <<'EOS'
zstyle ':antidote:bundle' path-style escaped
echo 'foo/bar' | bundle_parser | print_parsed_bundle
EOS
  expected=$(cat <<'EOF'
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-fakegitsite.com-SLASH-foo-SLASH-bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar
EOF
)
  expect "$expected"
}

@test "parsed path bundle matrix rows" {
  parser_session <<'EOS'
echo '$ZSH_CUSTOM/foo' | bundle_parser | print_parsed_bundle
EOS
  expected=$(cat <<'EOF'
__bundle__  : $ZSH_CUSTOM/foo
__type__    : path
EOF
)
  expect "$expected"
}

@test "parsed jibberish flags errors" {
  parser_session <<'EOS'
echo 'a b c d:e:f' | bundle_parser | print_parsed_bundle
echo 'foo bar:baz' | bundle_parser | print_parsed_bundle
EOS
  expected=$(cat <<'EOF'
__bundle__  : a
__error__   : error: Expecting 'key:value' form for annotation 'c'.
__severity__: error
__type__    : using_subplugin
d           : e:f
__bundle__  : foo
__error__   : invalid bundle 'foo'. Are you missing a 'using:' directive?
__severity__: error
__type__    : using_subplugin
bar         : baz
EOF
)
  expect "$expected"
}

@test "parsed matrix with every annotation" {
  parser_session <<'EOS'
echo 'foo/bar branch:baz kind:zsh path:plugins/baz pre:precmd post:"post cmd"' | bundle_parser | print_parsed_bundle
EOS
  expected=$(cat <<'EOF'
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar
branch      : baz
kind        : zsh
path        : plugins/baz
post        : post cmd
pre         : precmd
EOF
)
  expect "$expected"
}

@test "__type__ classification for many bundle forms" {
  parser_session <<'EOS'
echo 'foo/bar' | bundle_parser | bundle_val __type__
echo 'https://github.com/foo/bar' | bundle_parser | bundle_val __type__
echo 'git@bitbucket.org:foo/bar' | bundle_parser | bundle_val __type__
echo '$foo/bar' | bundle_parser | bundle_val __type__
echo '$foo/bar/baz.zsh' | bundle_parser | bundle_val __type__
echo '~foo/bar' | bundle_parser | bundle_val __type__
echo '~/foo' | bundle_parser | bundle_val __type__
echo './foo.zsh' | bundle_parser | bundle_val __type__
echo '../foo.zsh' | bundle_parser | bundle_val __type__
echo 'foo/bar/' | bundle_parser | bundle_val __type__
echo 'foo:bar' | bundle_parser | bundle_val __type__
echo 'bad@gitsite.com/foo/bar' | bundle_parser | bundle_val __type__
echo 'http:/badsite.com/foo/bar' | bundle_parser | bundle_val __type__
echo 'https://gitlab.com/group/subgroup/repo' | bundle_parser | bundle_val __type__
echo 'https://gist.github.com/abc123def456' | bundle_parser | bundle_val __type__
EOS
  expected=$(cat <<'EOF'
repo
url
ssh_url
path
path
path
path
path
path
?
?
?
?
url
url
EOF
)
  expect "$expected"
}

@test "invalid bundles emit an error" {
  parser_session <<'EOS'
echo 'foobar' | bundle_parser | print_parsed_bundle
echo 'foo/bar/baz' | bundle_parser | print_parsed_bundle
echo 'foo/bar/' | bundle_parser | print_parsed_bundle
EOS
  expected=$(cat <<'EOF'
__bundle__  : foobar
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
__type__    : ?
EOF
)
  expect "$expected"
}

@test "__url__ values" {
  parser_session <<'EOS'
echo 'foo/bar' | bundle_parser | bundle_val __url__
echo 'https://github.com/foo/bar' | bundle_parser | bundle_val __url__
echo 'git@bitbucket.org:foo/bar' | bundle_parser | bundle_val __url__
echo '$foo/bar' | bundle_parser | bundle_val __url__
echo 'bad@gitsite.com/foo/bar' | bundle_parser | bundle_val __url__
echo 'https://gitlab.com/group/subgroup/repo' | bundle_parser | bundle_val __url__
echo 'https://gist.github.com/abc123def456' | bundle_parser | bundle_val __url__
EOS
  expected=$(cat <<'EOF'
https://fakegitsite.com/foo/bar
https://github.com/foo/bar
git@bitbucket.org:foo/bar


https://gitlab.com/group/subgroup/repo
https://gist.github.com/abc123def456
EOF
)
  expect "$expected"
}

@test "__bundle__ preserves the original bundle text" {
  parser_session <<'EOS'
echo 'foo/bar' | bundle_parser | bundle_val __bundle__
echo 'https://github.com/foo/bar' | bundle_parser | bundle_val __bundle__
echo 'git@bitbucket.org:foo/bar' | bundle_parser | bundle_val __bundle__
echo '$foo/bar' | bundle_parser | bundle_val __bundle__
echo '$foo/bar/baz.zsh' | bundle_parser | bundle_val __bundle__
echo '~foo/bar' | bundle_parser | bundle_val __bundle__
echo '~/foo' | bundle_parser | bundle_val __bundle__
echo './foo.zsh' | bundle_parser | bundle_val __bundle__
echo '../foo.zsh' | bundle_parser | bundle_val __bundle__
echo 'foo/bar/' | bundle_parser | bundle_val __bundle__
echo 'foo:bar' | bundle_parser | bundle_val __bundle__
echo 'bad@gitsite.com/foo/bar' | bundle_parser | bundle_val __bundle__
echo 'http:/typo.com/foo/bar' | bundle_parser | bundle_val __bundle__
echo 'https://gitlab.com/group/subgroup/repo' | bundle_parser | bundle_val __bundle__
echo 'https://gist.github.com/abc123def456' | bundle_parser | bundle_val __bundle__
EOS
  expected=$(cat <<'EOF'
foo/bar
https://github.com/foo/bar
git@bitbucket.org:foo/bar
$foo/bar
$foo/bar/baz.zsh
~foo/bar
~/foo
./foo.zsh
../foo.zsh
foo/bar/
foo:bar
bad@gitsite.com/foo/bar
http:/typo.com/foo/bar
https://gitlab.com/group/subgroup/repo
https://gist.github.com/abc123def456
EOF
)
  expect "$expected"
}

@test "pin annotation is parsed" {
  parser_session <<'EOS'
echo 'foo/bar pin:abc123' | bundle_parser | print_parsed_bundle
EOS
  expected=$(cat <<'EOF'
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar
pin         : abc123
EOF
)
  expect "$expected"
}

@test "pin with kind:clone" {
  parser_session <<'EOS'
echo 'foo/bar kind:clone pin:64642c5691051ba0d82f5bda60b745f6fd042325' | bundle_parser | print_parsed_bundle
EOS
  expected=$(cat <<'EOF'
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar
kind        : clone
pin         : 64642c5691051ba0d82f5bda60b745f6fd042325
EOF
)
  expect "$expected"
}

@test "ssh url parsing" {
  parser_session <<'EOS'
echo 'git@bitbucket.org:foo/bar.git' | bundle_parser | bundle_val __type__
echo 'git@bitbucket.org:foo/bar.git' | bundle_parser | bundle_val __bundle__
echo 'git@bitbucket.org:foo/bar' | bundle_parser | bundle_val __short__
echo 'git@bitbucket.org:foo/bar.git' | bundle_parser | bundle_val __short__
EOS
  expected=$(cat <<'EOF'
ssh_url
git@bitbucket.org:foo/bar.git
git@bitbucket.org:foo/bar
git@bitbucket.org:foo/bar
EOF
)
  expect "$expected"
}

@test "ssh url __dir__" {
  parser_session <<'EOS'
echo 'git@fakegitsite.com:foo/qux' | bundle_parser | print_parsed_bundle
EOS
  expected=$(cat <<'EOF'
__bundle__  : git@fakegitsite.com:foo/qux
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/qux
__short__   : git@fakegitsite.com:foo/qux
__type__    : ssh_url
__url__     : git@fakegitsite.com:foo/qux
EOF
)
  expect "$expected"
}

@test "conditional, autoload, and fpath-rule annotations" {
  parser_session <<'EOS'
echo 'foo/bar conditional:is-macos' | bundle_parser | bundle_val conditional
echo 'foo/bar autoload:functions' | bundle_parser | bundle_val autoload
echo 'foo/bar fpath-rule:prepend' | bundle_parser | bundle_val fpath-rule
EOS
  expect "is-macos
functions
prepend"
}

@test "multiline input parses all bundles" {
  parser_session <<'EOS'
printf 'foo/bar\nbar/baz kind:clone\n' | bundle_parser | bundle_val __bundle__
printf 'foo/bar\nbar/baz kind:clone\n' | bundle_parser | bundle_val kind
printf '# comment\n\nfoo/bar\n' | bundle_parser | bundle_val __lineno__
EOS
  expected=$(cat <<'EOF'
foo/bar
bar/baz

clone
3
EOF
)
  expect "$expected"
}
