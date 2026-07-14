#!/usr/bin/env bats
# antidote bundle helper tests (ported from tests/test_bundle_helpers.md).
# Many 'bundle' tests could just as well be 'script' tests; this covers
# actual bundling and things not handled by 'antidote script'.

load helpers/common

setup() { antidote_common_setup; }

bundle_session() {
  SESSION_PRELUDE='antidote bundle <$ZDOTDIR/.base_test_fixtures.txt &>/dev/null' \
    run_session
}

# The repo parser pulls a list of all git URLs in a bundle file so that
# we can clone missing ones in parallel.
@test "bulk_clone emits parallel clone script" {
  bundle_session <<'EOS'
cat $T_TESTDATA/.zsh_plugins_repos.txt | antidote-zsh __private__ bulk_clone
EOS
  expected=$(cat <<'EOF'
zsh_script __bundle__ bar/baz kind clone &
zsh_script __bundle__ foobar/foobar kind clone branch baz &
zsh_script __bundle__ getantidote/zsh-defer kind clone &
zsh_script __bundle__ git@github.com:user/repo kind clone &
zsh_script __bundle__ http://github.com/user/repo.git kind clone &
zsh_script __bundle__ https://github.com/foo/baz kind clone &
zsh_script __bundle__ https://github.com/foo/qux kind clone &
zsh_script __bundle__ https://github.com/user/repo kind clone &
zsh_script __bundle__ user/repo kind clone &
wait
EOF
)
  expect "$expected"
}

@test "bulk_clone with empty input emits nothing" {
  bundle_session <<'EOS'
cat $T_TESTDATA/.zsh_plugins_empty.txt | antidote-zsh __private__ bulk_clone
EOS
  expect ""
}

@test "bundle_scripter emits zsh_script statements" {
  bundle_session <<'EOS'
echo foo/bar | antidote __private__ bundle_scripter
echo 'https://github.com/foo/bar path:lib branch:dev' | antidote __private__ bundle_scripter
echo 'git@github.com:foo/bar.git kind:clone branch:main' | antidote __private__ bundle_scripter
echo 'foo/bar kind:fpath abc:xyz' | antidote __private__ bundle_scripter
echo 'foo/bar path:plugins/myplugin kind:path  # trailing comment' | antidote __private__ bundle_scripter
EOS
  expected=$(cat <<'EOF'
zsh_script __bundle__ foo/bar __type__ repo
zsh_script __bundle__ https://github.com/foo/bar __type__ url branch dev path lib
zsh_script __bundle__ git@github.com:foo/bar.git __type__ ssh_url branch main kind clone
zsh_script __bundle__ foo/bar __type__ repo abc xyz kind fpath
zsh_script __bundle__ foo/bar __type__ repo kind path path plugins/myplugin
EOF
)
  expect "$expected"
}

# Track defers: only the first kind:defer bundle loads zsh-defer itself.
@test "bundle_scripter skips defer loader after the first defer" {
  bundle_session <<'EOS'
print 'foo/bar kind:defer\nbar/baz kind:defer\nbaz/qux kind:defer' | antidote __private__ bundle_scripter
EOS
  expected=$(cat <<'EOF'
zsh_script __bundle__ foo/bar __type__ repo kind defer
zsh_script __bundle__ bar/baz __type__ repo kind defer __skip_load_defer__ 1
zsh_script __bundle__ baz/qux __type__ repo kind defer __skip_load_defer__ 1
EOF
)
  expect "$expected"
}

@test "bundle_scripter handles funky whitespace" {
  bundle_session <<'EOS'
cr=$'\r'; lf=$'\n'; tab=$'\t'
echo "foo/bar${tab}kind:path${cr}${lf}" | antidote __private__ bundle_scripter
EOS
  expect "zsh_script __bundle__ foo/bar __type__ repo kind path"
}

# The bundle parser needs to properly handle quoted annotations.
@test "quoted conditional annotation survives parse, script, and bundle" {
  bundle_session <<'EOS'
bundle='foo/bar conditional:"is-macos || is-linux"'
echo $bundle | antidote __private__ bundle_parser_serialize | print_parsed_bundle
echo $bundle | antidote __private__ bundle_scripter
antidote bundle $bundle
EOS
  expected=$(cat <<'EOF'
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar
conditional : is-macos || is-linux
zsh_script __bundle__ foo/bar __type__ repo conditional 'is-macos || is-linux'
if is-macos || is-linux; then
  fpath+=( "$HOME/.cache/antidote/fakegitsite.com/foo/bar" )
  source "$HOME/.cache/antidote/fakegitsite.com/foo/bar/bar.plugin.zsh"
fi
EOF
)
  expect "$expected"
}

@test "quoted pre/post annotations survive parse, script, and bundle" {
  bundle_session <<'EOS'
bundle="foo/bar pre:'echo hello \$world' post:\"echo \\\"goodbye \$world\\\"\""
echo $bundle
echo $bundle | antidote __private__ bundle_parser_serialize | print_parsed_bundle
echo $bundle | antidote __private__ bundle_scripter
antidote bundle $bundle
EOS
  expected=$(cat <<'EOF'
foo/bar pre:'echo hello $world' post:"echo \"goodbye $world\""
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar
post        : echo "goodbye $world"
pre         : echo hello $world
zsh_script __bundle__ foo/bar __type__ repo post 'echo "goodbye $world"' pre 'echo hello $world'
echo hello $world
fpath+=( "$HOME/.cache/antidote/fakegitsite.com/foo/bar" )
source "$HOME/.cache/antidote/fakegitsite.com/foo/bar/bar.plugin.zsh"
echo "goodbye $world"
EOF
)
  expect "$expected"
}

# The bundle parser turns the bundle DSL into zsh_script statements.
@test "bundle_scripter handles the full ZDOTDIR plugins file" {
  bundle_session <<'EOS'
antidote __private__ bundle_scripter < $ZDOTDIR/.zsh_plugins.txt
EOS
  expected=$(cat <<'EOF'
zsh_script __bundle__ ~/foo/bar __type__ path
zsh_script __bundle__ '$ZSH_CUSTOM' __type__ empty path plugins/myplugin
zsh_script __bundle__ foo/bar __type__ repo
zsh_script __bundle__ git@fakegitsite.com:foo/qux.git __type__ ssh_url
zsh_script __bundle__ getantidote/zsh-defer __type__ repo kind clone
zsh_script __bundle__ foo/bar __type__ repo kind zsh
zsh_script __bundle__ foo/bar __type__ repo kind fpath
zsh_script __bundle__ foo/bar __type__ repo kind path
zsh_script __bundle__ ohmy/ohmy __type__ repo path lib
zsh_script __bundle__ ohmy/ohmy __type__ repo path plugins/extract
zsh_script __bundle__ ohmy/ohmy __type__ repo kind defer path plugins/magic-enter
zsh_script __bundle__ ohmy/ohmy __type__ repo path custom/themes/pretty.zsh-theme
EOF
)
  expect "$expected"
}
