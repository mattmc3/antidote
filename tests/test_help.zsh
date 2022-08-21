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
  antidote -h &>/dev/null
  @test "antidote -h succeeds" $? -eq 0
}

() {
  antidote --help &>/dev/null
  @test "antidote --help succeeds" $? -eq 0
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
  bundles
  help
  home
  init
  install
  list
  load
  path
  purge
  selfupdate
  update
)

() {
  local c cc expected actual err
  for c in $cmds; do
    # there are probably too many ways to call help
    for cmd in "antidote -h $c" "antidote $c -h"; do
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
  local cmd expected actual err
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
