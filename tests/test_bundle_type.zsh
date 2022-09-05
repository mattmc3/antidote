#!/usr/bin/env zsh
0=${(%):-%x}
autoload -Uz ${0:A:h}/functions/testinit && testinit
ztap_header "${0:t:r}"

# setup
source $BASEDIR/antidote.zsh
@echo "ZSH_VERSION: $ZSH_VERSION"

() {
  local actual expected exitcode
  antidote -v &>/dev/null
  @test "'antidote -v' succeeds" "$?" -eq 0
}

() {
  local actual exitcode
  local REPLY=

  local success_tests=(
    "typeset -A testdata=( bundle $FAKEZDOTDIR/aliases.zsh  type file )"
    "typeset -A testdata=( bundle $FAKEZDOTDIR/custom       type dir )"
    "typeset -A testdata=( bundle foo/bar      type repo )"
    "typeset -A testdata=( bundle bar/baz.git  type repo )"
    "typeset -A testdata=( bundle git@github.com:foo/bar.git      type url )"
    "typeset -A testdata=( bundle https://github.com/foo/bar.git  type url )"
  )

  for teststr in $success_tests; do
    eval $teststr
    __antidote_bundle_type $testdata[bundle] &>/dev/null
    exitcode=$?
    @test "'__antidote_bundle_type $testdata[bundle]' succeeds" $exitcode -eq 0
    @test "\$REPLY was set to '$testdata[type]'" "$REPLY" = "$testdata[type]"
  done
}

() {
  local actual exitcode stderr
  local REPLY=

  local fail_tests=(
    foo
    $FAKEZDOTDIR/fake.noexist
  )

  for bundle in $fail_tests; do
    eval $teststr
    stderr=$(__antidote_bundle_type $bundle 3>&1 1>/dev/null 2>&3)
    exitcode=$?
    @test "'__antidote_bundle_type $bundle' fails" $exitcode -ne 0
    @test "stderr has text" -n "$stderr"
    @test "\$REPLY is empty" -z "$REPLY"
  done
}

ztap_footer
