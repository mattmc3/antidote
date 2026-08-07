#!/usr/bin/env bats
# antidote respects setopts.
# These need run_session: the behavior under test is option state in
# the shell that runs antidote.

load helpers/common

setup() { antidote_common_setup; }

@test "plugins that run setopts take effect through antidote load" {
  run_session <<'EOS'
plugin=$ANTIDOTE_HOME/fakegitsite.com/lampoon/xmas/xmas.plugin.zsh
mkdir -p $plugin:h
print 'unsetopt noaliases\nsetopt autocd' > $plugin
echo "lampoon/xmas" > $ZDOTDIR/.zsh_plugins.txt
setopt noaliases
echo "before: noaliases=$options[noaliases] autocd=$options[autocd]"
antidote load >/dev/null
echo "after: noaliases=$options[noaliases] autocd=$options[autocd]"
EOS
  assert_line --index 0 "before: noaliases=on autocd=off"
  assert_line --index 1 "after: noaliases=off autocd=on"
}

# Ensure #86 stays fixed: no stderr noise under posix_identifiers.
@test "no stderr noise under posix_identifiers" {
  run_session <<'EOS'
setopt posix_identifiers
err=$(antidote -v 2>&1 >/dev/null);   print -r -- "-v: exit=$? stderr=[$err]"
err=$(antidote -h 2>&1 >/dev/null);   print -r -- "-h: exit=$? stderr=[$err]"
err=$(antidote help 2>&1 >/dev/null); print -r -- "help: exit=$? stderr=[$err]"
EOS
  assert_line "-v: exit=0 stderr=[]"
  assert_line "-h: exit=0 stderr=[]"
  assert_line "help: exit=0 stderr=[]"
}

# Special zsh options that change parsing/expansion semantics must not
# break antidote or leak state changes. See issue #154.
@test "bundle output is unaffected by KSH_ARRAYS and SH_GLOB" {
  SESSION_PRELUDE='setopt KSH_ARRAYS SH_GLOB'
  fixture_session <<'EOS'
antidote bundle <$ZDOTDIR/.zsh_plugins.txt | subenv
EOS
  expect "$(cat "$PRJDIR/tests/testdata/.zsh_plugins.zsh")"
}

# load runs a nested dispatch (load -> bundle), and the option
# save/restore has to survive the nesting without losing the options.
@test "nested dispatch through load preserves KSH_ARRAYS and SH_GLOB" {
  SESSION_PRELUDE='setopt KSH_ARRAYS SH_GLOB'
  fixture_session <<'EOS'
antidote load >/dev/null 2>&1
echo "ksh_arrays=${options[ksharrays]} sh_glob=${options[shglob]}"
EOS
  assert_line "ksh_arrays=on sh_glob=on"
}

@test "dispatch preserves KSH_ARRAYS and SH_GLOB" {
  SESSION_PRELUDE='setopt KSH_ARRAYS SH_GLOB'
  fixture_session <<'EOS'
antidote bundle foo/bar >/dev/null
echo "ksh_arrays=${options[ksharrays]} sh_glob=${options[shglob]}"
unsetopt KSH_ARRAYS SH_GLOB
antidote bundle foo/bar >/dev/null
echo "ksh_arrays=${options[ksharrays]} sh_glob=${options[shglob]}"
EOS
  assert_line --index 0 "ksh_arrays=on sh_glob=on"
  assert_line --index 1 "ksh_arrays=off sh_glob=off"
}

# A plugin that enables zillions of zsh options must have all of them
# take effect.
@test "bedlam plugin lights up all the zsh options" {
  run_session <<'EOS'
setopt | wc -l | tr -d ' '
echo '$ZDOTDIR/custom/plugins/bedlam' > $ZDOTDIR/.zsh_plugins.txt
antidote load
setopt | wc -l | tr -d ' '
EOS
  [ "${#lines[@]}" -eq 2 ]
  [ "${lines[0]}" -lt 10 ]
  [ "${lines[1]}" -gt 150 ]
}

# The generated script is sourced in the user's shell under whatever options
# they have set, so it cannot depend on zsh array indexing.
@test "an autoloaded functions dir still loads under KSH_ARRAYS" {
  SESSION_PRELUDE='setopt KSH_ARRAYS'
  run_session <<'EOS'
mkdir -p $ZDOTDIR/myfuncs
print 'print ran-myfunc' >$ZDOTDIR/myfuncs/myfunc
antidote bundle "$ZDOTDIR/myfuncs kind:autoload" >$ZDOTDIR/out.zsh
source $ZDOTDIR/out.zsh
print "autoloadable: ${+functions[myfunc]}"
EOS
  assert_line "autoloadable: 1"
}

@test "an autoloaded functions dir still loads under KSH_ARRAYS with fpath-rule prepend" {
  SESSION_PRELUDE='setopt KSH_ARRAYS'
  run_session <<'EOS'
mkdir -p $ZDOTDIR/myfuncs
print 'print ran-myfunc' >$ZDOTDIR/myfuncs/myfunc
antidote bundle "$ZDOTDIR/myfuncs kind:autoload fpath-rule:prepend" >$ZDOTDIR/out.zsh
source $ZDOTDIR/out.zsh
print "autoloadable: ${+functions[myfunc]}"
EOS
  assert_line "autoloadable: 1"
}
