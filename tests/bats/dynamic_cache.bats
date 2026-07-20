#!/usr/bin/env bats
# Dynamic-mode script cache (antidote-bundle-dynamic).
#
# The sentinel pattern proves a warm serve: append `echo cache hit` to a
# cached script file, rerun the line, and the sentinel only prints if the
# cached copy is what actually ran. The .zwc must be removed alongside,
# or zsh serves the stale compiled copy.

load helpers/common

setup() { antidote_common_setup; }

@test "dynamic bundle caches its script and serves it warm" {
  run_session <<'EOS'
source <(antidote init)
antidote bundle foo/bar &>/dev/null
wait_for_files "$ANTIDOTE_HOME/.dynamic/[0-9]*.zsh"
scripts=($ANTIDOTE_HOME/.dynamic/[0-9]*.zsh(N))
echo "scripts: $#scripts"
print 'echo cache hit' >>$scripts[1]
antidote bundle foo/bar
EOS
  assert_line "scripts: 1"
  assert_line "cache hit"
  assert_line "sourcing bar.plugin.zsh from foo/bar..."
}

# zcompile is opt-in: without the zstyle, no .zwc files are written.
@test "cache files are not zcompiled by default" {
  run_session <<'EOS'
source <(antidote init)
antidote bundle foo/bar &>/dev/null
wait_for_files "$ANTIDOTE_HOME/.dynamic/[0-9]*.zsh"
zwcs=($ANTIDOTE_HOME/.dynamic/*.zwc(N))
echo "zwc files: $#zwcs"
EOS
  assert_line "zwc files: 0"
}

# With the zstyle set, cache files are zcompiled and a warm serve works
# from the .zwc alone (the .zsh removed).
@test "zcompile zstyle compiles cache files and serves from the zwc" {
  run_session <<'EOS'
zstyle ':antidote:dynamic' zcompile yes
source <(antidote init)
antidote bundle foo/bar &>/dev/null
wait_for_files "$ANTIDOTE_HOME/.dynamic/[0-9]*.zsh.zwc"
zwcs=($ANTIDOTE_HOME/.dynamic/[0-9]*.zsh.zwc(N))
echo "zwc files: $#zwcs"
scripts=($ANTIDOTE_HOME/.dynamic/[0-9]*.zsh(N))
rm $scripts[1]
antidote bundle foo/bar
EOS
  assert_line "zwc files: 1"
  assert_line "sourcing bar.plugin.zsh from foo/bar..."
}

@test "dynamic bundle returns success warm and cold" {
  run_session <<'EOS'
source <(antidote init)
antidote bundle foo/bar &>/dev/null; echo "cold exit: $?"
wait_for_files "$ANTIDOTE_HOME/.dynamic/[0-9]*.zsh"
antidote bundle foo/bar &>/dev/null; echo "warm exit: $?"
EOS
  assert_line "cold exit: 0"
  assert_line "warm exit: 0"
}

# Reset the using: context and replay the chain. Each line must resolve
# to its own input-keyed cache file.
@test "using: chain serves warm from disk" {
  run_session <<'EOS'
source <(antidote init)
antidote bundle using:ohmy/ohmy path:plugins &>/dev/null
antidote bundle docker &>/dev/null
antidote bundle extract &>/dev/null
wait_for_files "$ANTIDOTE_HOME/.dynamic/[0-9]*.zsh" 3
for f in $ANTIDOTE_HOME/.dynamic/[0-9]*.zsh(N); do
  print '(( cache_hits++ ))' >>$f
done
typeset -gi cache_hits=0
_antidote_using_context=()
echo "--- warm ---"
antidote bundle using:ohmy/ohmy path:plugins
antidote bundle docker
antidote bundle extract
echo "cache hits: $cache_hits"
EOS
  expected=$(cat <<'EOF'
--- warm ---
sourcing plugins/docker/docker.plugin.zsh from ohmy/ohmy...
sourcing plugins/extract/extract.plugin.zsh from ohmy/ohmy...
cache hits: 3
EOF
)
  expect "$expected"
}

# Same bare word under a different using: context is a different cache
# entry, never a stale crossover.
@test "using: context changes produce distinct cache entries" {
  run_session <<'EOS'
source <(antidote init)
antidote bundle using:ohmy/ohmy path:plugins &>/dev/null
antidote bundle docker &>/dev/null
antidote bundle using:$ZDOTDIR/custom path:plugins &>/dev/null
antidote bundle docker &>/dev/null
wait_for_files "$ANTIDOTE_HOME/.dynamic/[0-9]*.zsh" 4
files=($ANTIDOTE_HOME/.dynamic/[0-9]*.zsh(N))
echo "cache files: $#files"
EOS
  assert_line "cache files: 4"
}

@test "zstyle set before first bundle does not error" {
  run_session <<'EOS'
zstyle ':antidote:fpath' rule append
source <(antidote init)
antidote bundle foo/bar
EOS
  refute_line --partial "bad math expression"
  assert_line "sourcing bar.plugin.zsh from foo/bar..."
}

# Changing an ':antidote:*' zstyle hashes to a different cache file.
@test "zstyle changes switch to a separate cache file" {
  run_session <<'EOS'
source <(antidote init)
antidote bundle foo/bar &>/dev/null
wait_for_files "$ANTIDOTE_HOME/.dynamic/[0-9]*.zsh"
for f in $ANTIDOTE_HOME/.dynamic/[0-9]*.zsh(N); do
  print 'echo cache hit' >>$f
  rm -f $f.zwc
done
zstyle ':antidote:fpath' rule prepend
antidote bundle foo/bar
wait_for_files "$ANTIDOTE_HOME/.dynamic/[0-9]*.zsh" 2
files=($ANTIDOTE_HOME/.dynamic/[0-9]*.zsh(N))
echo "cache files: $#files"
EOS
  refute_line "cache hit"
  assert_line "sourcing bar.plugin.zsh from foo/bar..."
  assert_line "cache files: 2"
}

# Flipping back to the original zstyles reuses its original cache file.
@test "alternating zstyles keep separate warm cache files" {
  run_session <<'EOS'
source <(antidote init)
antidote bundle foo/bar &>/dev/null
wait_for_files "$ANTIDOTE_HOME/.dynamic/[0-9]*.zsh"
file=($ANTIDOTE_HOME/.dynamic/[0-9]*.zsh([1]))
print 'print original cache loaded' >>$file
zstyle ':antidote:fpath' rule prepend
antidote bundle foo/bar &>/dev/null
wait_for_files "$ANTIDOTE_HOME/.dynamic/[0-9]*.zsh" 2
zstyle -d ':antidote:fpath' rule
antidote bundle foo/bar
EOS
  assert_line "original cache loaded"
  assert_line "sourcing bar.plugin.zsh from foo/bar..."
}

# A changed config file mtime hashes to a different cache file.
@test "cache regenerates when the config file is newer" {
  run_session <<'EOS'
source <(antidote init)
antidote bundle foo/bar &>/dev/null
wait_for_files "$ANTIDOTE_HOME/.dynamic/[0-9]*.zsh"
for f in $ANTIDOTE_HOME/.dynamic/[0-9]*.zsh(N); do
  print 'echo cache hit' >>$f
  rm -f $f.zwc
done
touch -t 203801010000 $ANTIDOTE_CONFIG
antidote bundle foo/bar
wait_for_files "$ANTIDOTE_HOME/.dynamic/[0-9]*.zsh" 2
scripts=($ANTIDOTE_HOME/.dynamic/[0-9]*.zsh(N))
echo "cache files: $#scripts"
EOS
  refute_line "cache hit"
  assert_line "sourcing bar.plugin.zsh from foo/bar..."
  assert_line "cache files: 2"
}

@test "purge clears the cache so bundles reclone" {
  run_session <<'EOS'
source <(antidote init)
antidote bundle foo/bar &>/dev/null
wait_for_files "$ANTIDOTE_HOME/.dynamic/[0-9]*.zsh"
antidote purge foo/bar &>/dev/null
[[ -d $ANTIDOTE_HOME/.dynamic ]] && echo "cache dir present" || echo "cache dir gone"
antidote bundle foo/bar
wait_for_files "$ANTIDOTE_HOME/.dynamic/[0-9]*.zsh"
EOS
  assert_line "cache dir gone"
  assert_line "# antidote cloning foo/bar..."
  assert_line "sourcing bar.plugin.zsh from foo/bar..."
}

# Bundle contents can change on update, so update flushes the cache.
@test "update clears the dynamic cache" {
  run_session <<'EOS'
source <(antidote init)
antidote bundle foo/bar &>/dev/null
wait_for_files "$ANTIDOTE_HOME/.dynamic/[0-9]*.zsh"
[[ -d $ANTIDOTE_HOME/.dynamic ]] && echo "cache dir present"
antidote update --bundles &>/dev/null
[[ -d $ANTIDOTE_HOME/.dynamic ]] || echo "cache dir gone"
EOS
  assert_line "cache dir present"
  assert_line "cache dir gone"
}

# A warm source failure is returned without regenerating and sourcing
# the same plugin a second time.
@test "warm source failures do not run twice" {
  run_session <<'EOS'
source <(antidote init)
antidote bundle foo/bar &>/dev/null
wait_for_files "$ANTIDOTE_HOME/.dynamic/[0-9]*.zsh"
rm -rf $ANTIDOTE_HOME/fakegitsite.com/foo/bar
antidote bundle foo/bar 2>/dev/null || echo "source failed"
EOS
  assert_line "source failed"
  refute_line --partial "antidote cloning"
}

@test "piped bundles bypass the cache" {
  run_session <<'EOS'
source <(antidote init)
antidote bundle <<EOB &>/dev/null
foo/bar
foo/baz
EOB
echo "plugins: $#plugins"
[[ -d $ANTIDOTE_HOME/.dynamic ]] && echo "cache dir present" || echo "cache dir absent"
EOS
  assert_line "plugins: 2"
  assert_line "cache dir absent"
}

@test "annotated and plain lines cache separately" {
  run_session <<'EOS'
source <(antidote init)
antidote bundle foo/bar &>/dev/null
antidote bundle foo/bar kind:fpath &>/dev/null
wait_for_files "$ANTIDOTE_HOME/.dynamic/[0-9]*.zsh" 2
files=($ANTIDOTE_HOME/.dynamic/[0-9]*.zsh(N))
echo "cache files: $#files"
EOS
  assert_line "cache files: 2"
}

@test "multiline bundle args cache and serve warm" {
  run_session <<'EOS'
source <(antidote init)
antidote bundle $'foo/bar\nfoo/baz' &>/dev/null
wait_for_files "$ANTIDOTE_HOME/.dynamic/[0-9]*.zsh"
files=($ANTIDOTE_HOME/.dynamic/[0-9]*.zsh(N))
echo "cache files: $#files"
for f in $ANTIDOTE_HOME/.dynamic/[0-9]*.zsh(N); do
  print 'echo cache hit' >>$f
  rm -f $f.zwc
done
antidote bundle $'foo/bar\nfoo/baz'
EOS
  assert_line "cache files: 1"
  assert_line "sourcing bar.plugin.zsh from foo/bar..."
  assert_line "sourcing baz.plugin.zsh from foo/baz..."
  assert_line "cache hit"
}

@test "deferred bundles cache and serve warm" {
  run_session <<'EOS'
source <(antidote init)
antidote bundle ohmy/ohmy path:plugins/magic-enter kind:defer &>/dev/null
echo "zsh-defer after cold: $+functions[zsh-defer]"
wait_for_files "$ANTIDOTE_HOME/.dynamic/[0-9]*.zsh"
for f in $ANTIDOTE_HOME/.dynamic/[0-9]*.zsh(N); do
  print 'echo cache hit' >>$f
  rm -f $f.zwc
done
antidote bundle ohmy/ohmy path:plugins/magic-enter kind:defer
EOS
  assert_line "zsh-defer after cold: 1"
  assert_line "cache hit"
}

@test "local path bundles cache and serve warm" {
  run_session <<'EOS'
source <(antidote init)
antidote bundle $ZDOTDIR/custom/lib &>/dev/null
echo "libs after cold: $#libs"
wait_for_files "$ANTIDOTE_HOME/.dynamic/[0-9]*.zsh"
for f in $ANTIDOTE_HOME/.dynamic/[0-9]*.zsh(N); do
  print 'echo cache hit' >>$f
  rm -f $f.zwc
done
antidote bundle $ZDOTDIR/custom/lib
EOS
  assert_line "cache hit"
}

# Warm evals run in the caller's context, so plugin setopts stick just
# like they do when sourcing a static file.
@test "plugin setopts stick on warm serves" {
  run_session <<'EOS'
source <(antidote init)
antidote bundle $ZDOTDIR/custom/plugins/grizwold &>/dev/null
[[ -o globdots ]] && echo "cold setopt ok"
wait_for_files "$ANTIDOTE_HOME/.dynamic/[0-9]*.zsh"
unsetopt globdots
antidote bundle $ZDOTDIR/custom/plugins/grizwold &>/dev/null
[[ -o globdots ]] && echo "warm setopt ok"
EOS
  assert_line "cold setopt ok"
  assert_line "warm setopt ok"
}

@test "invalid bundle is not cached and fails" {
  run_session <<'EOS'
source <(antidote init)
antidote bundle 'bad:bundle:value' 2>&1 >/dev/null; echo "exit: $?"
files=($ANTIDOTE_HOME/.dynamic/[0-9]*.zsh(N))
echo "cache files: $#files"
EOS
  assert_line --partial "invalid bundle"
  assert_line "exit: 1"
  assert_line "cache files: 0"
}

@test "invalid bundle from stdin fails" {
  run_session <<'EOS'
source <(antidote init)
print -r -- 'bad:bundle:value' | antidote bundle 2>/dev/null
echo "exit: $?"
EOS
  assert_line "exit: 1"
}

@test "failed clone is not cached and fails" {
  run_session <<'EOS'
source <(antidote init)
antidote bundle does-not/exist 2>/dev/null; echo "exit: $?"
files=($ANTIDOTE_HOME/.dynamic/[0-9]*.zsh(N))
echo "cache files: $#files"
EOS
  assert_line "exit: 1"
  assert_line "cache files: 0"
}
