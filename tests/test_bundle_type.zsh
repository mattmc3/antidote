#!/usr/bin/env zsh
0=${(%):-%x}
autoload -Uz ${0:A:h}/functions/testinit && testinit
ztap_header "${0:t:r}"

# setup
source $BASEDIR/antidote.zsh

# load antidote-script and its private functions
antidote-script &>/dev/null

() {
  local actual exitcode teststr
  local REPLY=

  local success_tests=(
    "typeset -A testdata=( bundle $FAKEZDOTDIR/aliases.zsh  type file )"
    "typeset -A testdata=( bundle $FAKEZDOTDIR/custom       type dir )"
    "typeset -A testdata=( bundle git@github.com:foo/bar.git      type sshurl )"
    "typeset -A testdata=( bundle https://github.com/foo/bar.git  type url )"
    "typeset -A testdata=( bundle https:/bad.com/foo/bar.git      type unk )"
    "typeset -A testdata=( bundle ''             type empty )"
    "typeset -A testdata=( bundle '    '         type empty )"
    "typeset -A testdata=( bundle /foo/bar       type path )"
    "typeset -A testdata=( bundle /foobar        type path )"
    "typeset -A testdata=( bundle foobar/        type relpath )"
    "typeset -A testdata=( bundle '~/foo/bar'    type path )"
    "typeset -A testdata=( bundle '$foo/bar'     type path )"
    "typeset -A testdata=( bundle foo/bar        type repo )"
    "typeset -A testdata=( bundle baz/qux.git    type repo )"
    "typeset -A testdata=( bundle 'foo/baz/qux'  type relpath )"
    "typeset -A testdata=( bundle foobar         type word )"
    "typeset -A testdata=( bundle 'foo bar baz'  type word )"
  )

  for teststr in $success_tests; do
    eval $teststr
    __antidote_bundle_type $testdata[bundle] &>/dev/null
    exitcode=$?
    @test "'__antidote_bundle_type $testdata[bundle]' succeeds" $exitcode -eq 0
    @test "\$REPLY was set to '$testdata[type]'" "$REPLY" = "$testdata[type]"
  done
}

ztap_footer
