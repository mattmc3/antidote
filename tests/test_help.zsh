#!/usr/bin/env zsh
0=${(%):-%x}
autoload -Uz ${0:A:h}/functions/testinit && testinit
ztap_header "${0:t:r}"

# setup
ANTIDOTE_HOME=$BASEDIR/tests/fakezdotdir/antidote_home
source $BASEDIR/antidote.zsh

export MANPAGER=cat
export PAGER=cat

() {
  local arg
  for arg in 'help' '-h' '--help'
  do
    antidote $arg &>/dev/null
    @test "'antidote $arg' succeeds" $? -eq 0
  done
}

() {
  local actual expected err
  expected="antidote - the cure to slow zsh plugin management"
  actual=("${(@f)$(antidote 2>&1)}")
  err=$?
  @test "'antidote' without args fails" $err -ne 0
  @test "'antidote' without args prints help" "$actual[1]" = "$expected"
}

cmds=(
  bundle
  help
  home
  init
  install
  list
  load
  path
  purge
  # script
  update
)

() {
  local c cmd expected actual err helpcmds
  for c in $cmds; do
    # there are too many ways to call help, but there you have it
    helpcmds=(
      "antidote help $c"
      "antidote -h $c"
      "antidote --help $c"
      "antidote $c -h"
      "antidote $c --help"
    )
    for cmd in $helpcmds; do
      if [[ "$c" = bundles ]]; then
        expected="antidote-bundle(1)"
      elif [[ -n "$c" ]]; then
        expected="antidote-${c}(1)"
      else
        expected="antidote(1)"
      fi
      actual=($(eval $cmd 2>&1))
      err=$?
      @test "'$cmd' should succeed" $err -eq 0
      @test "'$cmd' should show man page '$expected'" "$actual[1]" = "$expected"
    done
  done
}

() {
  local c cmd expected actual err
  local badcmds=(foobar)
  for c in $badcmds; do
    cmd="antidote -h $c"
    actual=$(eval $cmd 2>&1)
    err=$?
    actual=("${(@f)actual}")
    expected="No manual entry for antidote-$c"
    @test "'$cmd' should fail" $err -eq 1
    @test "'$cmd' should print default help" "$expected" = "${actual[1]}"
  done
}

ztap_footer
