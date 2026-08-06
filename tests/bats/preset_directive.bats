#!/usr/bin/env bats
# antidote preset: directive tests.
# preset:<repo> sets fallback annotations for every later entry of that
# repo, so pin: and branch: need not be repeated on each line.

load helpers/common

setup_file() { antidote_fixture_proto; }

setup() {
  antidote_common_setup
  antidote_test_home_cached
}

# Emit the _parsed_bundles matrix as stable "row,key=value" lines, so
# annotations that never reach the static file can be asserted. typeset -p
# formats associative arrays differently across zsh versions, so normalize
# rather than matching its output.
parse() {
  local serialized
  serialized=$(antidote __private__ bundle_parser_serialize "$@")
  run zsh -fc 'eval "$1"
    for k in ${(ok)_parsed_bundles}; do print -r -- "$k=${_parsed_bundles[$k]}"; done' \
    zsh "$serialized"
}

PIN=4f8a1c2b9e7d3a6f5c0b8e2d7a9f4c1b6e3d8a52

##### inheritance

@test "preset: supplies pin to a later line of the same repo" {
  parse <<EOS
preset:foo/bar pin:$PIN
foo/bar path:lib
EOS
  assert_success
  assert_output --partial "1,pin=$PIN"
  # the preset: line itself produces no entry
  assert_output --partial '__count__=1'
}

# the whole point: repeating a pin per line used to be mandatory
@test "preset: pin removes the inconsistent pin error" {
  run antidote bundle <<EOS
preset:pintest/pinme pin:$PIN_V110
pintest/pinme
pintest/pinme kind:clone
EOS
  assert_success
  refute_output --partial "inconsistent pin"
}

@test "preset: applies any annotation, not just pin and branch" {
  parse <<'EOS'
preset:foo/bar conditional:is_macos kind:fpath pre:setup
foo/bar path:lib
EOS
  assert_output --partial '1,conditional=is_macos'
  assert_output --partial '1,kind=fpath'
  assert_output --partial '1,pre=setup'
}

@test "a line-level annotation wins over preset" {
  parse <<'EOS'
preset:foo/bar branch:frompreset
foo/bar path:lib branch:fromline
EOS
  assert_output --partial '1,branch=fromline'
}

@test "preset: applies to bare words under using:" {
  parse <<EOS
preset:foo/bar pin:$PIN
using:foo/bar path:plugins
docker
EOS
  assert_output --partial "1,pin=$PIN"
  assert_output --partial "2,pin=$PIN"
}

# kind: has to behave like every other preset annotation, even though using:
# gives bare names a default kind of its own
@test "preset: kind reaches bare names under using:" {
  parse <<'EOS'
preset:foo/bar kind:fpath
using:foo/bar path:plugins
docker
EOS
  assert_output --partial '2,kind=fpath'
}

@test "a bare name still defaults to kind zsh with no preset" {
  parse <<'EOS'
using:foo/bar path:plugins
docker
EOS
  assert_output --partial '2,kind=zsh'
}

# using: is the block you are inside, so it is more specific than preset
@test "a using: annotation wins over preset" {
  parse <<'EOS'
preset:foo/bar branch:frompreset
using:foo/bar branch:fromusing
docker
EOS
  assert_output --partial '2,branch=fromusing'
  refute_output --partial 'frompreset'
}

##### keying

# one clone per repo, so every spelling of it shares preset
@test "preset: is keyed by clone directory, not by text" {
  parse <<EOS
preset:foo/bar pin:$PIN
https://fakegitsite.com/foo/bar
EOS
  assert_output --partial "1,pin=$PIN"
}

@test "preset: declared by URL applies to the short repo form" {
  parse <<EOS
preset:https://fakegitsite.com/foo/bar pin:$PIN
foo/bar
EOS
  assert_output --partial "1,pin=$PIN"
}

@test "preset: for one repo does not leak to another" {
  parse <<EOS
preset:foo/bar pin:$PIN
foo/baz
EOS
  refute_output --partial "1,pin="
}

@test "preset: works for a local path bundle" {
  parse <<'EOS'
preset:$HOME/plugins/foo kind:fpath
$HOME/plugins/foo
EOS
  assert_output --partial '1,kind=fpath'
}

##### ordering

@test "preset: only applies to lines below it" {
  parse <<EOS
foo/bar path:lib
preset:foo/bar pin:$PIN
EOS
  refute_output --partial "1,pin="
}

@test "a later preset: for the same repo wins" {
  parse <<'EOS'
preset:foo/bar branch:one
preset:foo/bar branch:two
foo/bar
EOS
  assert_output --partial '1,branch=two'
}

# a represet is a whole-set replacement, not a merge
@test "a later preset: drops keys the first one set" {
  parse <<'EOS'
preset:foo/bar pre:setup_func
preset:foo/bar post:teardown_func
foo/bar
EOS
  assert_output --partial '1,post=teardown_func'
  refute_output --partial 'setup_func'
}

@test "preset: accumulate across repos without replacing each other" {
  parse <<'EOS'
preset:foo/bar branch:barbranch
preset:foo/baz branch:bazbranch
foo/bar
foo/baz
EOS
  assert_output --partial '1,branch=barbranch'
  assert_output --partial '2,branch=bazbranch'
}

##### errors

@test "preset: with an empty target is an error" {
  run antidote bundle 'preset:'
  assert_failure 1
  assert_line "# antidote: error on line 1: invalid preset: target ''"
}

@test "preset: with a malformed target is an error" {
  run antidote bundle 'preset:foo@bar'
  assert_failure 1
  assert_line "# antidote: error on line 1: invalid preset: target 'foo@bar'"
}

##### output

@test "preset: alone clones nothing and emits no script" {
  run antidote bundle "preset:foo/bar pin:$PIN"
  refute_output --partial "cloning"
  refute_output --partial 'fakegitsite.com/foo/bar'
}

@test "a preset pin reaches the generated script the same as a literal one" {
  local viapreset literal
  literal=$(antidote bundle "pintest/pinme pin:$PIN_V110" 2>/dev/null)
  viapreset=$(antidote bundle 2>/dev/null <<EOS
preset:pintest/pinme pin:$PIN_V110
pintest/pinme
EOS
  )
  [ -n "$literal" ] && [ "$literal" = "$viapreset" ]
}
