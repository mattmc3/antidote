0=${(%):-%N}
@echo "=== ${0:t:r} ==="

autoload -Uz ${0:a:h}/functions/setup && setup

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
  local c expected actual
  for c in '' $cmds; do
    cmd="antidote -h $c"
    if [[ "$c" = bundles ]]; then
      expected="antidote-bundle(1)"
    elif [[ -n "$c" ]]; then
      expected="antidote-${c}(1)"
    else
      expected="antidote(1)"
    fi
    actual=($(eval $cmd 2>&1))
    errcode=$?
    @test "'$cmd' should succeed" $errcode -eq 0
    @test "'$cmd' should show man page '$expected'" "$actual[1]" = "$expected"
  done
}

() {
  local cmd expected actual errcode
  local badcmds=(foobar)
  for c in $badcmds; do
    cmd="antidote -h $c"
    actual=$(eval $cmd 2>&1)
    errcode=$?
    actual=("${(@f)actual}")
    expected="No manual entry for antidote-$c"
    @test "'$cmd' should fail" $errcode -eq 1
    @test "'$cmd' should print default help" "$expected" = "${actual[1]}"
  done
}

teardown
