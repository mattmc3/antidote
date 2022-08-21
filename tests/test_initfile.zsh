0=${(%):-%x}
@echo "=== ${0:t:r} ==="

autoload -Uz ${0:a:h}/functions/setup && setup

success_tests=(
  "typeset -A testdata=( [dir]=foo        [file]=foo.zsh )"
  "typeset -A testdata=( [dir]=bar        [file]=bar.plugin.zsh )"
  "typeset -A testdata=( [dir]=baz        [file]=baz.zsh-theme )"
  "typeset -A testdata=( [dir]=z          [file]=z.sh )"
  "typeset -A testdata=( [dir]=zsh-plugin [file]=plugin.zsh )"
  "typeset -A testdata=( [dir]=plugin.zsh [file]=whatever.zsh )"
)

REPLY=
for teststr in $success_tests; do
  eval $teststr
  plugindir=$TEMP_HOME/$testdata[dir]
  expected=$plugindir/$testdata[file]
  mkdir -p $plugindir && touch $expected

  _antidote_initfiles $plugindir &>/dev/null
  errcode=$?
  @test "_antidote_initfiles returns success for $testdata[dir]" $errcode -eq 0
  @test "\$REPLY was set with initfile" "$REPLY" = $expected

  actual=$(_antidote_initfiles $plugindir)
  @test "$testdata[file] initfile detected" "$actual" = $expected

  rm -rf "$plugindir"
done

fail_tests=(
  "typeset -A testdata=( [dir]=foo        [file]=foo.bash )"
  "typeset -A testdata=( [dir]=bar        [file]=README.md )"
  "typeset -A testdata=( [dir]=baz        [file]=baz )"
)
for teststr in $fail_tests; do
  eval $teststr
  plugindir=$TEMP_HOME/$testdata[dir]
  mkdir -p $plugindir && touch $plugindir/$testdata[file]

  _antidote_initfiles $plugindir &>/dev/null
  errcode=$?
  @test "_antidote_initfiles returns fail code for $testdata[dir]" $errcode -ne 0
  @test "\$REPLY was set to empty" "$REPLY" = ""

  rm -rf "$plugindir"
done

teardown
