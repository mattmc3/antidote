#!/usr/bin/env zsh
0=${(%):-%x}
autoload -Uz ${0:A:h}/functions/testinit && testinit
ztap_header "${0:t:r}"

# setup
source $BASEDIR/antidote.zsh
TMPDIR=$BASEDIR/.tmp/tests/initfile
[[ -d $TMPDIR ]] && rm -rf "$TMPDIR"

() {
  local expected actual exitcode
  local plugindir teststr REPLY=

  local success_tests=(
    "typeset -A testdata=( dir myplugin     file myplugin.plugin.zsh )"
    "typeset -A testdata=( dir malformed    file whatever.plugin.zsh )"
    "typeset -A testdata=( dir myprompt     file myprompt.zsh )"
    "typeset -A testdata=( dir mytheme      file mytheme.zsh-theme )"
    "typeset -A testdata=( dir name         file name.zsh )"
    "typeset -A testdata=( dir shellscript  file shellscript.sh )"
    "typeset -A testdata=( dir zsh-name     file name.zsh )"
  )

  for teststr in $success_tests; do
    eval $teststr
    plugindir=$TMPDIR/$testdata[dir]
    expected=$plugindir/$testdata[file]
    mkdir -p $plugindir && touch $expected

    _antidote_initfiles $plugindir &>/dev/null
    exitcode=$?
    @test "_antidote_initfiles returns success for $testdata[dir]" $exitcode -eq 0
    @test "\$REPLY was correctly set to '$testdata[file]'" "$REPLY" = $expected

    actual=$(_antidote_initfiles $plugindir)
    @test "$testdata[file] initfile detected" "$actual" = $expected
  done
}

() {
  fail_tests=(
    "typeset -A testdata=( dir foo        file foo.bash )"
    "typeset -A testdata=( dir bar        file README.md )"
    "typeset -A testdata=( dir baz        file baz )"
    "typeset -A testdata=( dir notaplugin file '' )"
  )
  for teststr in $fail_tests; do
    eval $teststr
    plugindir=$TMPDIR/$testdata[dir]
    mkdir -p $plugindir
    if [[ -n "$testdata[file]" ]]; then
      touch $plugindir/$testdata[file]
    fi
    _antidote_initfiles $plugindir &>/dev/null
    exitcode=$?
    @test "_antidote_initfiles returns fail code for $testdata[dir]" $exitcode -ne 0
    @test "\$REPLY is empty" -z "$REPLY"
  done
}

ztap_footer
