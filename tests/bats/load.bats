#!/usr/bin/env bats
# antidote load tests. load runs in the parent shell
# (functions/antidote-load), so these use sessions.

load helpers/common

setup() { antidote_common_setup; }

@test "load sources every bundle in the plugins file" {
  fixture_session <<<'antidote load $ZDOTDIR/.zplugins_fake_load'
  expected=$(cat <<'EOF'
sourcing bar.plugin.zsh from foo/bar...
sourcing qux.plugin.zsh from foo/qux...
sourcing bar.plugin.zsh from foo/bar...
sourcing lib/lib1.zsh from ohmy/ohmy...
sourcing lib/lib2.zsh from ohmy/ohmy...
sourcing lib/lib3.zsh from ohmy/ohmy...
sourcing plugins/extract/extract.plugin.zsh from ohmy/ohmy...
sourcing plugins/docker/docker.plugin.zsh from ohmy/ohmy...
sourcing plugins/docker/docker.plugin.zsh from ohmy/ohmy...
sourcing zsh-defer.plugin.zsh from getantidote/zsh-defer...
sourcing plugins/magic-enter/magic-enter.plugin.zsh from ohmy/ohmy...
sourcing custom/themes/pretty.zsh-theme from ohmy/ohmy...
EOF
)
  expect "$expected"
}

@test "load writes the golden static file" {
  fixture_session <<'EOS'
antidote load $ZDOTDIR/.zplugins_fake_load >/dev/null
cat $ZDOTDIR/.zplugins_fake_load.zsh | subenv
EOS
  expect "$(cat "$PRJDIR/tests/testdata/.zplugins_fake_load.zsh")"
}

@test "load fails when bundle and static file are the same" {
  SESSION_PRELUDE="cp \$ZDOTDIR/.zplugins_fake_load \$ZDOTDIR/.zplugins.txt
zstyle ':antidote:bundle' file \$ZDOTDIR/.zplugins.txt
zstyle ':antidote:static' file \$ZDOTDIR/.zplugins.txt"
  fixture_session <<<'antidote load 2>&1 | subenv ZDOTDIR'
  assert_output "antidote: bundle file and static file are the same '\$ZDOTDIR/.zplugins.txt'."
}

@test "load honors bundle and static file zstyles" {
  SESSION_PRELUDE="cp \$ZDOTDIR/.zplugins_fake_load \$ZDOTDIR/.zplugins.txt
zstyle ':antidote:bundle' file \$ZDOTDIR/.zplugins.txt
zstyle ':antidote:static' file \$ZDOTDIR/.zplugins.static.zsh"
  fixture_session <<'EOS'
antidote load >/dev/null; print "load exit: $?"
print "static lines: $(wc -l <$ZDOTDIR/.zplugins.static.zsh)"
EOS
  assert_line --index 0 "load exit: 0"
  assert_line --index 1 --regexp 'static lines: +[1-9][0-9]*$'
}

# The checkfile forces a one-time rebundle. It lands under ANTIDOTE_HOME.
@test "load writes the checkfile under ANTIDOTE_HOME" {
  fixture_session <<'EOS'
antidote load $ZDOTDIR/.zplugins_fake_load >/dev/null 2>&1
[[ -e $ANTIDOTE_HOME/.antidote.load ]] && echo "checkfile present" || echo "checkfile absent"
EOS
  assert_line "checkfile present"
}

# antidote-home resolves ANTIDOTE_HOME in the parent shell (no
# subprocess). Guard against that resolver drifting from the real
# subprocess resolution: across every OS branch, parent antidote-home
# must equal what the antidote.zsh subprocess reports.
@test "antidote-home matches the subprocess across OS branches" {
  SESSION_PRELUDE='unset ANTIDOTE_HOME'
  fixture_session <<'EOS'
for os in darwin21.3.0 msys foobar; do
  zstyle ':antidote:test:env' OSTYPE $os
  [[ $os == msys ]] && zstyle ':antidote:test:env' LOCALAPPDATA $HOME/AppData
  parent=$(antidote home)
  sub=$(antidote-zsh home)
  [[ $parent == $sub ]] && echo "$os: match" || echo "$os: MISMATCH parent=$parent sub=$sub"
done
EOS
  assert_line "darwin21.3.0: match"
  assert_line "msys: match"
  assert_line "foobar: match"
}

# Only the subprocess sources the config file, so a config-file
# ':antidote:home' has to reach the parent resolver too.
@test "antidote-home honors a config-file home" {
  SESSION_PRELUDE='unset ANTIDOTE_HOME
export ANTIDOTE_CONFIG=$HOME/cfg.zsh
print -r -- "zstyle \":antidote:home\" dir \$HOME/custom-home" >$ANTIDOTE_CONFIG
antidote-setup'
  run_session <<'EOS'
parent=$(antidote home)
sub=$(antidote-zsh home)
[[ $parent == $sub ]] && echo "match: ${parent:t}" || echo "MISMATCH parent=$parent sub=$sub"
EOS
  assert_output "match: custom-home"
}

# A broken ANTIDOTE_ZSH makes any subprocess call fail, so answering
# here proves the config file was read in this shell.
@test "antidote-home reads a config-file home without a subprocess" {
  SESSION_PRELUDE='unset ANTIDOTE_HOME
export ANTIDOTE_CONFIG=$HOME/cfg.zsh
print -r -- "zstyle \":antidote:home\" dir \$HOME/custom-home" >$ANTIDOTE_CONFIG
antidote-setup
echo "exit 3" >$HOME/broken.zsh
ANTIDOTE_ZSH=$HOME/broken.zsh'
  run_session <<<'echo "${$(antidote home):t}"'
  assert_success
  assert_output "custom-home"
}

# The autoload route runs antidote-setup after the user's zstyles, so
# the config file must not overwrite what this shell already set.
@test "a zstyle set before setup beats the config file" {
  SESSION_PRELUDE='unset ANTIDOTE_HOME
export ANTIDOTE_CONFIG=$HOME/cfg.zsh
print -rl -- "zstyle \":antidote:home\" dir \$HOME/from-config" \
  "zstyle \":antidote:bundle\" path-style short" >$ANTIDOTE_CONFIG
zstyle ":antidote:home" dir $HOME/from-shell
antidote-setup'
  run_session <<'EOS'
echo "home: ${$(antidote home):t}"
echo "path-style: $(zstyle -L :antidote:bundle path-style)"
EOS
  assert_line "home: from-shell"
  assert_line "path-style: zstyle :antidote:bundle path-style short"
}

# update deletes the checkfile from the real ANTIDOTE_HOME, so load has
# to write it there or the forced rebundle after an update never fires.
@test "load writes the checkfile to a config-file home" {
  SESSION_PRELUDE='unset ANTIDOTE_HOME
export ANTIDOTE_CONFIG=$HOME/cfg.zsh
print -r -- "zstyle \":antidote:home\" dir \$HOME/custom-home" >$ANTIDOTE_CONFIG
antidote-setup
print -r -- "$ZDOTDIR/custom/lib" >$ZDOTDIR/.zplugins_localdir.txt'
  run_session <<'EOS'
antidote load $ZDOTDIR/.zplugins_localdir.txt >/dev/null 2>&1
[[ -e $HOME/custom-home/.antidote.load ]] && echo "checkfile in real home" || echo "checkfile elsewhere"
EOS
  assert_line "checkfile in real home"
}

@test "load fails on a missing bundle file" {
  fixture_session <<<'antidote load /no/such/file.txt 2>&1'
  assert_output "antidote: bundle file not found '/no/such/file.txt'."
}

@test "load fails with exit 2 when the static file cannot be created" {
  SESSION_PRELUDE='zstyle ":antidote:load:checkfile" disabled true
touch $ZDOTDIR/.zplugins_err.txt $HOME/blocker'
  fixture_session <<<'antidote load $ZDOTDIR/.zplugins_err.txt $HOME/blocker/static.zsh 2>/dev/null'
  assert_failure 2
}

@test "load fails with exit 2 when the static file fails to source" {
  SESSION_PRELUDE='zstyle ":antidote:load:checkfile" disabled true
touch -t 202001010000 $ZDOTDIR/.zplugins_err.txt
print "false" > $ZDOTDIR/.zplugins_err.zsh'
  fixture_session <<<'antidote load $ZDOTDIR/.zplugins_err.txt $ZDOTDIR/.zplugins_err.zsh'
  assert_failure 2
}

# tmux panes after an update: every shell sees a stale static file and
# rebuilds at once. Real child shells, not subshells, since zsh keeps $$
# at the parent pid in a subshell and they would share one temp.
@test "concurrent loads all rebuild and source the static file" {
  SESSION_PRELUDE='antidote load $ZDOTDIR/.zplugins_fake_load &>/dev/null
touch $ZDOTDIR/.zplugins_fake_load'
  fixture_session <<'EOS'
for i in 1 2 3 4; do
  zsh -f -c "source \$T_PRJDIR/antidote.zsh
antidote load \$ZDOTDIR/.zplugins_fake_load >\$ZDOTDIR/out.$i 2>&1
print \"load $i: \$? \$(grep -c '^sourcing' \$ZDOTDIR/out.$i)\"" &
done
wait
temps=($ZDOTDIR/..zplugins_fake_load.zsh.new.*(N))
print "temps: $#temps"
EOS
  assert_line "load 1: 0 12"
  assert_line "load 2: 0 12"
  assert_line "load 3: 0 12"
  assert_line "load 4: 0 12"
  assert_line "temps: 0"
}

# A shell killed mid-rebuild orphans its temp. The next rebuild reaps
# the old ones in the background, sparing any young enough to belong to
# a live rebuild. Poll: the reaper is detached, so wait cannot see it.
@test "rebuild sweeps orphaned temps but spares fresh ones" {
  SESSION_PRELUDE='antidote load $ZDOTDIR/.zplugins_fake_load &>/dev/null
print orphan > $ZDOTDIR/..zplugins_fake_load.zsh.new.99998
touch -t 202001010000 $ZDOTDIR/..zplugins_fake_load.zsh.new.99998
print inflight > $ZDOTDIR/..zplugins_fake_load.zsh.new.99999
touch $ZDOTDIR/.zplugins_fake_load'
  fixture_session <<'EOS'
antidote load $ZDOTDIR/.zplugins_fake_load &>/dev/null
for i in {1..40}; do
  temps=($ZDOTDIR/..zplugins_fake_load.zsh.new.*(N))
  (( $#temps == 1 )) && break
  sleep 0.1
done
print "temps: ${(j: :)${temps[@]:t}}"
EOS
  assert_line "temps: ..zplugins_fake_load.zsh.new.99999"
}

@test "failed regeneration preserves the last known-good static file" {
  SESSION_PRELUDE='print "bad:bundle:value" > $ZDOTDIR/.zplugins_bad.txt
print "print last-known-good" > $ZDOTDIR/.zplugins_bad.zsh'
  run_session <<'EOS'
antidote load $ZDOTDIR/.zplugins_bad.txt $ZDOTDIR/.zplugins_bad.zsh 2>/dev/null
echo "exit: $?"
grep -q last-known-good $ZDOTDIR/.zplugins_bad.zsh && echo "static preserved" || echo "static clobbered"
temps=($ZDOTDIR/..zplugins_bad.zsh.new.*(N))
echo "temps: $#temps"
[[ -e $ANTIDOTE_HOME/.antidote.load ]] && echo "checkfile present" || echo "checkfile absent"
EOS
  assert_line "last-known-good"
  assert_line "exit: 1"
  assert_line "static preserved"
  assert_line "temps: 0"
  assert_line "checkfile absent"
}
