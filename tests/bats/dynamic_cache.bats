#!/usr/bin/env bats
# Dynamic-mode manifest script cache (antidote-bundle-dynamic).
#
# The sentinel pattern proves a warm serve: append `echo cache hit` to a
# cached script file (or the manifest on disk), rerun the line, and the
# sentinel only prints if the cached copy is what actually ran. The .zwc
# must be removed alongside, or zsh serves the stale compiled copy. A
# regenerated entry lands in a fresh file and loses the sentinel.

load helpers/common

setup() { antidote_common_setup; }

@test "dynamic bundle caches its script and serves it warm" {
  run_session <<'EOS'
source <(antidote init)
antidote bundle foo/bar &>/dev/null
manifests=($ANTIDOTE_HOME/.dynamic/manifest-*.zsh(N))
echo "manifests: $#manifests"
scripts=($ANTIDOTE_HOME/.dynamic/[0-9]*.zsh(N))
echo "scripts: $#scripts"
echo "entries: $#_antidote_dynamic_cache"
print 'echo cache hit' >>$scripts[1]
antidote bundle foo/bar
EOS
  assert_line "manifests: 1"
  assert_line "scripts: 1"
  assert_line "entries: 1"
  assert_line "cache hit"
  assert_line "sourcing bar.plugin.zsh from foo/bar..."
}

# zcompile is opt-in: without the zstyle, no .zwc files are written.
@test "cache files are not zcompiled by default" {
  run_session <<'EOS'
source <(antidote init)
antidote bundle foo/bar &>/dev/null
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
antidote bundle foo/bar &>/dev/null; echo "warm exit: $?"
EOS
  assert_line "cold exit: 0"
  assert_line "warm exit: 0"
}

# Simulate a fresh shell: reset the using: context and the in-memory
# cache so the manifest reloads from disk. All three lines must serve
# from the manifest (the appended sentinel proves it loads; an
# unchanged line count proves nothing regenerated).
@test "using: chain serves warm from the manifest" {
  run_session <<'EOS'
source <(antidote init)
antidote bundle using:ohmy/ohmy path:plugins &>/dev/null
antidote bundle docker &>/dev/null
antidote bundle extract &>/dev/null
mfile=($ANTIDOTE_HOME/.dynamic/manifest-*.zsh([1]))
print 'print manifest loaded' >>$mfile
before=$(wc -l <$mfile)
_antidote_using_context=() _antidote_dynamic_cache=() _antidote_dynamic_meta=()
echo "--- warm ---"
antidote bundle using:ohmy/ohmy path:plugins
antidote bundle docker
antidote bundle extract
after=$(wc -l <$mfile)
[[ $before -eq $after ]] && echo "no regen" || echo "regen happened: $before -> $after"
EOS
  expected=$(cat <<'EOF'
--- warm ---
manifest loaded
sourcing plugins/docker/docker.plugin.zsh from ohmy/ohmy...
sourcing plugins/extract/extract.plugin.zsh from ohmy/ohmy...
no regen
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
echo "docker entries: ${#${(@M)${(@k)_antidote_dynamic_cache}:#docker*}}"
EOS
  assert_line "docker entries: 2"
}

# Fresh shell with zstyles set: the first lookup reads
# _antidote_dynamic_meta[zstyles] before the assoc exists. An unset
# param math-evals the subscript, and `zstyles` holds ':antidote:...'.
@test "zstyle set before first bundle does not error" {
  run_session <<'EOS'
zstyle ':antidote:fpath' rule append
source <(antidote init)
antidote bundle foo/bar
EOS
  refute_line --partial "bad math expression"
  assert_line "sourcing bar.plugin.zsh from foo/bar..."
}

# Changing an ':antidote:*' zstyle hashes to a different manifest, and
# a script the zstyle alters lands in a different content-addressed
# file, so the sentinel from the old combo must not be served. Rule
# prepend, not append: append is the default and would generate an
# identical (shared) script file.
@test "zstyle changes switch to a separate manifest" {
  run_session <<'EOS'
source <(antidote init)
antidote bundle foo/bar &>/dev/null
for f in $ANTIDOTE_HOME/.dynamic/[0-9]*.zsh(N); do
  print 'echo cache hit' >>$f
  rm -f $f.zwc
done
zstyle ':antidote:fpath' rule prepend
antidote bundle foo/bar
manifests=($ANTIDOTE_HOME/.dynamic/manifest-*.zsh(N))
echo "manifests: $#manifests"
EOS
  refute_line "cache hit"
  assert_line "sourcing bar.plugin.zsh from foo/bar..."
  assert_line "manifests: 2"
}

# Both zstyle combos keep their own warm manifest; flipping back must
# serve the original combo's cache from disk, not regenerate.
@test "alternating zstyle combos keep separate warm manifests" {
  run_session <<'EOS'
source <(antidote init)
antidote bundle foo/bar &>/dev/null
mfile=($ANTIDOTE_HOME/.dynamic/manifest-*.zsh([1]))
print 'print original manifest loaded' >>$mfile
zstyle ':antidote:fpath' rule prepend
antidote bundle foo/bar &>/dev/null
zstyle -d ':antidote:fpath' rule
antidote bundle foo/bar
EOS
  assert_line "original manifest loaded"
  assert_line "sourcing bar.plugin.zsh from foo/bar..."
}

# A changed config file mtime invalidates the manifest header,
# discarding stale entries. Future-dated touch: mtimes have one-second
# granularity, and the cold write above happens in the same second.
# The regenerated script matches its filename hash but not the
# tampered content, so the store bumps to a suffixed file rather than
# reuse it - this also covers the collision path.
@test "cache regenerates when the config file is newer" {
  run_session <<'EOS'
source <(antidote init)
antidote bundle foo/bar &>/dev/null
for f in $ANTIDOTE_HOME/.dynamic/[0-9]*.zsh(N); do
  print 'echo cache hit' >>$f
  rm -f $f.zwc
done
touch -t 203801010000 $ANTIDOTE_CONFIG
antidote bundle foo/bar
scripts=($ANTIDOTE_HOME/.dynamic/[0-9]*-2.zsh(N))
echo "suffixed: $#scripts"
EOS
  refute_line "cache hit"
  assert_line "sourcing bar.plugin.zsh from foo/bar..."
  assert_line "suffixed: 1"
}

@test "purge clears the cache so bundles reclone" {
  run_session <<'EOS'
source <(antidote init)
antidote bundle foo/bar &>/dev/null
antidote purge foo/bar &>/dev/null
[[ -d $ANTIDOTE_HOME/.dynamic ]] && echo "cache dir present" || echo "cache dir gone"
_antidote_dynamic_cache=() _antidote_dynamic_meta=()
antidote bundle foo/bar
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
[[ -d $ANTIDOTE_HOME/.dynamic ]] && echo "cache dir present"
antidote update --bundles &>/dev/null
[[ -d $ANTIDOTE_HOME/.dynamic ]] || echo "cache dir gone"
EOS
  assert_line "cache dir present"
  assert_line "cache dir gone"
}

# A bundle dir deleted out-of-band (not via purge) makes the cached
# script fail to eval; the fallback regenerates and reclones.
@test "deleted bundle self-heals on a warm eval" {
  run_session <<'EOS'
source <(antidote init)
antidote bundle foo/bar &>/dev/null
rm -rf $ANTIDOTE_HOME/fakegitsite.com/foo/bar
antidote bundle foo/bar 2>/dev/null; echo "exit: $?"
EOS
  assert_line "sourcing bar.plugin.zsh from foo/bar..."
  assert_line "exit: 0"
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
echo "entries: $#_antidote_dynamic_cache"
EOS
  assert_line "entries: 2"
}

@test "multiline bundle args cache and serve warm" {
  run_session <<'EOS'
source <(antidote init)
antidote bundle $'foo/bar\nfoo/baz' &>/dev/null
echo "entries: $#_antidote_dynamic_cache"
for f in $ANTIDOTE_HOME/.dynamic/[0-9]*.zsh(N); do
  print 'echo cache hit' >>$f
  rm -f $f.zwc
done
antidote bundle $'foo/bar\nfoo/baz'
EOS
  assert_line "entries: 1"
  assert_line "sourcing bar.plugin.zsh from foo/bar..."
  assert_line "sourcing baz.plugin.zsh from foo/baz..."
  assert_line "cache hit"
}

@test "deferred bundles cache and serve warm" {
  run_session <<'EOS'
source <(antidote init)
antidote bundle ohmy/ohmy path:plugins/magic-enter kind:defer &>/dev/null
echo "zsh-defer after cold: $+functions[zsh-defer]"
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
echo "entries: $#_antidote_dynamic_cache"
manifests=($ANTIDOTE_HOME/.dynamic/manifest-*.zsh(N))
echo "manifests: $#manifests"
EOS
  assert_line --partial "invalid bundle"
  assert_line "exit: 1"
  assert_line "entries: 0"
  assert_line "manifests: 0"
}

@test "failed clone is not cached and fails" {
  run_session <<'EOS'
source <(antidote init)
antidote bundle does-not/exist 2>/dev/null; echo "exit: $?"
echo "entries: $#_antidote_dynamic_cache"
EOS
  assert_line "exit: 1"
  assert_line "entries: 0"
}
