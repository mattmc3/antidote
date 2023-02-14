#!/usr/bin/env zsh
0=${(%):-%x}
autoload -Uz ${0:A:h}/functions/testinit && testinit
ztap_header "${0:t:r}"

# setup
source $BASEDIR/antidote.zsh
setup_fakezdotdir update
function git { mockgit "$@" }

# -h|--help
() {
  antidote update -h &>/dev/null
  @test "'antidote update -h' succeeds" "$?" -eq 0
  antidote update --help &>/dev/null
  @test "'antidote update --help' succeeds" "$?" -eq 0
}

# antidote update
() {
  local actual expected exitcode
  expected=(
    "Updating bundles..."
    "antidote: checking for updates: git@github.com:bar/baz"
    "antidote: checking for updates: https://github.com/baz/qux"
    "antidote: checking for updates: https://github.com/foo/bar"
    "antidote: checking for updates: https://github.com/ohmy/ohmy"
    "antidote: checking for updates: https://github.com/romkatv/zsh-defer"
    "Waiting for bundle updates to complete..."
    "Bundle updates complete."
    "Updating antidote..."
    "Antidote self-update complete."
    ""
    "$(antidote --version 2>&1)"
  )
  actual=("$(antidote update $bundle)"); exitcode=$?
  actual=("${(@f)actual}")
  @test "'antidote update' succeeds" $exitcode -eq 0
  @test "'antidote update' works" "$expected" = "$actual"
}

ztap_footer

# teardown
ZDOTDIR=$OLD_ZDOTDIR
unfunction git
