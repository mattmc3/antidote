#!/usr/bin/env bats
# antidote bundle fpath-rule:<rule> tests

load helpers/common

setup() { antidote_common_setup; }

@test "fpath is appended to by default" {
  fixture_session <<'EOS'
antidote bundle foo/bar kind:fpath
EOS
  assert_output 'fpath+=( "$HOME/.cache/antidote/fakegitsite.com/foo/bar" )'
}

# fpath can be told to explicitly append, but it's unnecessary
@test "explicit fpath-rule:append works" {
  fixture_session <<'EOS'
antidote bundle foo/bar kind:zsh fpath-rule:append
EOS
  expect 'fpath+=( "$HOME/.cache/antidote/fakegitsite.com/foo/bar" )
source "$HOME/.cache/antidote/fakegitsite.com/foo/bar/bar.plugin.zsh"'
}

@test "fpath-rule:prepend prepends" {
  fixture_session <<'EOS'
antidote bundle foo/bar kind:fpath fpath-rule:prepend
EOS
  assert_output 'fpath=( "$HOME/.cache/antidote/fakegitsite.com/foo/bar" $fpath )'
}

@test "fpath rules can only be append or prepend" {
  fixture_session <<'EOS'
antidote bundle foo/bar kind:fpath fpath-rule:append >/dev/null; echo "append exit: $?"
antidote bundle foo/bar kind:fpath fpath-rule:prepend >/dev/null; echo "prepend exit: $?"
antidote bundle foo/bar kind:fpath fpath-rule:foo 2>&1
EOS
  assert_failure 1
  assert_line "append exit: 0"
  assert_line "prepend exit: 0"
  assert_line "# antidote: error: unexpected fpath rule: 'foo'"
}

@test "fpath rules apply to kind:autoload" {
  fixture_session <<'EOS'
antidote bundle foo/baz path:baz kind:autoload fpath-rule:append
antidote bundle foo/baz path:baz kind:autoload fpath-rule:prepend
EOS
  expected=$(cat <<'EOF'
fpath+=( "$HOME/.cache/antidote/fakegitsite.com/foo/baz/baz" )
builtin autoload -Uz $fpath[-1]/*(N.:t)
fpath=( "$HOME/.cache/antidote/fakegitsite.com/foo/baz/baz" $fpath )
builtin autoload -Uz $fpath[1]/*(N.:t)
EOF
)
  expect "$expected"
}

@test "fpath rules apply to autoload:funcdir annotations" {
  fixture_session <<'EOS'
antidote bundle foo/baz autoload:baz fpath-rule:append
antidote bundle foo/baz autoload:baz fpath-rule:prepend
EOS
  expected=$(cat <<'EOF'
fpath+=( "$HOME/.cache/antidote/fakegitsite.com/foo/baz/baz" )
builtin autoload -Uz $fpath[-1]/*(N.:t)
fpath+=( "$HOME/.cache/antidote/fakegitsite.com/foo/baz" )
source "$HOME/.cache/antidote/fakegitsite.com/foo/baz/baz.plugin.zsh"
fpath=( "$HOME/.cache/antidote/fakegitsite.com/foo/baz/baz" $fpath )
builtin autoload -Uz $fpath[1]/*(N.:t)
fpath=( "$HOME/.cache/antidote/fakegitsite.com/foo/baz" $fpath )
source "$HOME/.cache/antidote/fakegitsite.com/foo/baz/baz.plugin.zsh"
EOF
)
  expect "$expected"
}

# fpath rules can be set globally with a zstyle:
#   zstyle ':antidote:fpath' rule 'prepend'
@test "global fpath rule zstyle" {
  fixture_session <<'EOS'
zstyle ':antidote:fpath' rule 'prepend'
antidote bundle foo/bar
antidote bundle foo/bar kind:fpath
antidote bundle foo/baz path:baz kind:autoload
EOS
  expected=$(cat <<'EOF'
fpath=( "$HOME/.cache/antidote/fakegitsite.com/foo/bar" $fpath )
source "$HOME/.cache/antidote/fakegitsite.com/foo/bar/bar.plugin.zsh"
fpath=( "$HOME/.cache/antidote/fakegitsite.com/foo/bar" $fpath )
fpath=( "$HOME/.cache/antidote/fakegitsite.com/foo/baz/baz" $fpath )
builtin autoload -Uz $fpath[1]/*(N.:t)
EOF
)
  expect "$expected"
}

# It is NOT recommended, but explicit fpath-rules still beat the zstyle.
@test "explicit fpath-rule overrides the global zstyle" {
  fixture_session <<'EOS'
zstyle ':antidote:fpath' rule 'prepend'
antidote bundle foo/bar fpath-rule:append
antidote bundle foo/bar kind:fpath fpath-rule:append
antidote bundle foo/baz path:baz kind:autoload fpath-rule:append
EOS
  expected=$(cat <<'EOF'
fpath+=( "$HOME/.cache/antidote/fakegitsite.com/foo/bar" )
source "$HOME/.cache/antidote/fakegitsite.com/foo/bar/bar.plugin.zsh"
fpath+=( "$HOME/.cache/antidote/fakegitsite.com/foo/bar" )
fpath+=( "$HOME/.cache/antidote/fakegitsite.com/foo/baz/baz" )
builtin autoload -Uz $fpath[-1]/*(N.:t)
EOF
)
  expect "$expected"
}
