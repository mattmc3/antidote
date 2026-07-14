#!/usr/bin/env bats
# antidote using: directive tests (ported from tests/test_using_directive.md)

load helpers/common

setup() { antidote_common_setup; }

# Same shorthand the clitest file used; clone the base fixtures since
# the full-fixture case sources real cloned bundles.
using_session() {
  SESSION_PRELUDE='antidote bundle <$ZDOTDIR/.base_test_fixtures.txt &>/dev/null
function bundle_parser() { antidote __private__ bundle_parser_serialize "$@"; }' \
    run_session
}

# using: alone emits a single clone entry
@test "using: alone emits a single clone entry" {
  using_session <<'EOS'
echo 'using:foo/bar' | bundle_parser | print_parsed_bundle
EOS
  expected=$(cat <<'EOF'
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar
kind        : clone
EOF
)
  expect "$expected"
}

# using: with path: — clone entry has no path, path is only a prefix for words
@test "using: with path: keeps the clone entry pathless" {
  using_session <<'EOS'
echo 'using:foo/bar path:plugins' | bundle_parser | print_parsed_bundle
EOS
  expected=$(cat <<'EOF'
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar
kind        : clone
EOF
)
  expect "$expected"
}

# using: with kind: — kind becomes the default for words, clone entry is always clone
@test "using: kind: is the default for words, clone entry stays clone" {
  using_session <<'EOS'
printf 'using:foo/bar path:plugins kind:fpath\nextract\n' | bundle_parser | print_parsed_bundle
EOS
  expected=$(cat <<'EOF'
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar
kind        : clone
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : using_subplugin
__url__     : https://fakegitsite.com/foo/bar
kind        : fpath
path        : plugins/extract
EOF
)
  expect "$expected"
}

@test "words after using: get default kind:zsh and path prefix" {
  using_session <<'EOS'
printf 'using:foo/bar path:plugins\nextract\ngit\n' | bundle_parser | print_parsed_bundle
EOS
  expected=$(cat <<'EOF'
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar
kind        : clone
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : using_subplugin
__url__     : https://fakegitsite.com/foo/bar
kind        : zsh
path        : plugins/extract
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : using_subplugin
__url__     : https://fakegitsite.com/foo/bar
kind        : zsh
path        : plugins/git
EOF
)
  expect "$expected"
}

@test "word-level kind: overrides using: default" {
  using_session <<'EOS'
printf 'using:foo/bar path:plugins kind:zsh\nextract kind:fpath\n' | bundle_parser | print_parsed_bundle
EOS
  expected=$(cat <<'EOF'
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar
kind        : clone
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : using_subplugin
__url__     : https://fakegitsite.com/foo/bar
kind        : fpath
path        : plugins/extract
EOF
)
  expect "$expected"
}

# using: annotations (branch, etc.) inherited by clone entry and all words
@test "using: annotations are inherited by clone entry and words" {
  using_session <<'EOS'
printf 'using:foo/bar path:plugins branch:baz\nextract\ngit\n' | bundle_parser | print_parsed_bundle
EOS
  expected=$(cat <<'EOF'
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar
branch      : baz
kind        : clone
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : using_subplugin
__url__     : https://fakegitsite.com/foo/bar
branch      : baz
kind        : zsh
path        : plugins/extract
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : using_subplugin
__url__     : https://fakegitsite.com/foo/bar
branch      : baz
kind        : zsh
path        : plugins/git
EOF
)
  expect "$expected"
}

@test "word-level annotation overrides inherited using: annotation" {
  using_session <<'EOS'
printf 'using:foo/bar path:plugins branch:main\nextract branch:dev\ngit\n' | bundle_parser | print_parsed_bundle
EOS
  expected=$(cat <<'EOF'
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar
branch      : main
kind        : clone
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : using_subplugin
__url__     : https://fakegitsite.com/foo/bar
branch      : dev
kind        : zsh
path        : plugins/extract
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : using_subplugin
__url__     : https://fakegitsite.com/foo/bar
branch      : main
kind        : zsh
path        : plugins/git
EOF
)
  expect "$expected"
}

# using: with no path: — word becomes the full path value
@test "using: with no path: makes the word the path" {
  using_session <<'EOS'
printf 'using:foo/bar\nextract\n' | bundle_parser | print_parsed_bundle
EOS
  expected=$(cat <<'EOF'
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar
kind        : clone
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : using_subplugin
__url__     : https://fakegitsite.com/foo/bar
kind        : zsh
path        : extract
EOF
)
  expect "$expected"
}

@test "word without active using: context is an error" {
  using_session <<'EOS'
echo 'extract' | bundle_parser | print_parsed_bundle
EOS
  expected=$(cat <<'EOF'
__bundle__  : extract
__error__   : invalid bundle 'extract'. Are you missing a 'using:' directive?
__severity__: error
__type__    : using_subplugin
EOF
)
  expect "$expected"
}

@test "using: with URL form" {
  using_session <<'EOS'
echo 'using:https://fakegitsite.com/foo/bar path:plugins' | bundle_parser | print_parsed_bundle | subenv ANTIDOTE_HOME
EOS
  expected=$(cat <<'EOF'
__bundle__  : https://fakegitsite.com/foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : url
__url__     : https://fakegitsite.com/foo/bar
kind        : clone
EOF
)
  expect "$expected"
}

@test "using: with SSH URL form" {
  using_session <<'EOS'
echo 'using:git@fakegitsite.com:foo/bar path:plugins' | bundle_parser | print_parsed_bundle | subenv ANTIDOTE_HOME
EOS
  expected=$(cat <<'EOF'
__bundle__  : git@fakegitsite.com:foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : git@fakegitsite.com:foo/bar
__type__    : ssh_url
__url__     : git@fakegitsite.com:foo/bar
kind        : clone
EOF
)
  expect "$expected"
}

@test "using: annotations like conditional: are inherited by words" {
  using_session <<'EOS'
printf 'using:foo/bar path:plugins conditional:is-macos\ndocker\n' | bundle_parser | print_parsed_bundle | subenv ANTIDOTE_HOME
EOS
  expected=$(cat <<'EOF'
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar
conditional : is-macos
kind        : clone
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : using_subplugin
__url__     : https://fakegitsite.com/foo/bar
conditional : is-macos
kind        : zsh
path        : plugins/docker
EOF
)
  expect "$expected"
}

@test "using: with empty target is an error" {
  using_session <<'EOS'
antidote bundle 'using:' 2>&1; echo "exit: $?"
EOS
  expect_any_order "# antidote: error on line 1: invalid using: target ''
exit: 1"
}

@test "using: with malformed target is an error" {
  using_session <<'EOS'
antidote bundle 'using:foo@bar' 2>&1; echo "exit: $?"
EOS
  expect_any_order "# antidote: error on line 1: invalid using: target 'foo@bar'
exit: 1"
}

# invalid bundle mixed with valid — error is shown but valid output is
# still produced. (The clitest original only asserted the exit code;
# its output text was stale documentation.)
@test "invalid bundle mixed with valid still produces valid output" {
  using_session <<'EOS'
printf 'foo/bar\nfoo\n' | antidote bundle 2>&1; echo "exit: $?"
EOS
  expected=$(cat <<'EOF'
# antidote: error on line 2: invalid bundle 'foo'. Are you missing a 'using:' directive?
fpath+=( "$HOME/.cache/antidote/fakegitsite.com/foo/bar" )
source "$HOME/.cache/antidote/fakegitsite.com/foo/bar/bar.plugin.zsh"
exit: 1
EOF
)
  expect "$expected"
}

# full fixture: multiple using: blocks, non-word passthrough, branch
# inheritance, context persistence
@test "full using: fixture matches golden output" {
  using_session <<'EOS'
antidote bundle <$T_TESTDATA/.zsh_plugins_using.txt | subenv ANTIDOTE_HOME HOME ZDOTDIR
EOS
  expect "$(cat "$PRJDIR/tests/testdata/.zsh_plugins_using.zsh")"
}
