#!/usr/bin/env bats
# antidote paths-with-spaces tests (ported from tests/test_paths_with_spaces.md)

load helpers/common

setup() { antidote_common_setup; }

# The bundle parser needs to properly handle quoted annotations, and
# ANTIDOTE_HOME dirs containing spaces must stay quoted in output.
@test "quoted annotations and ANTIDOTE_HOME with spaces" {
  run_session <<'EOS'
ANTIDOTE_HOME="$HOME/.cache/antidote with spaces"
mkdir -p -- "$ANTIDOTE_HOME"
echo 'foo/bar path:"plugins/foo bar/baz"' | antidote __private__ bundle_parser_serialize | print_parsed_bundle
echo 'foo/bar' | antidote __private__ bundle_scripter
antidote bundle 'foo/bar'
EOS
  expected=$(cat <<'EOF'
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar
path        : plugins/foo bar/baz
zsh_script __bundle__ foo/bar __type__ repo
# antidote cloning foo/bar...
fpath+=( "$HOME/.cache/antidote with spaces/fakegitsite.com/foo/bar" )
source "$HOME/.cache/antidote with spaces/fakegitsite.com/foo/bar/bar.plugin.zsh"
EOF
)
  expect "$expected"
}
