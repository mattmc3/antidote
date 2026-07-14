#!/usr/bin/env bats
# Real-world antidote tests (ported from tests/test_real.md). These hit
# real GitHub repos over the network — run via `just test-real`, never
# part of the unit suite.

load ../helpers/common

setup() {
  antidote_common_setup
  SESSION_SETUP=t_setup_real
  # Bundle the real plugins file once per session; most tests act on
  # the resulting clones.
  SESSION_PRELUDE='zstyle ":antidote:bundle:*" zcompile "yes"
zstyle ":antidote:test:version" show-sha off
zstyle ":antidote:test:git" autostash off
antidote bundle <$T_TESTDATA/.zsh_plugins.txt >$ZDOTDIR/.zsh_plugins.zsh 2>/dev/null'
}

@test "bundle generates the golden script from real repos" {
  run_session <<'EOS'
diff <(cat $ZDOTDIR/.zsh_plugins.zsh | subenv ANTIDOTE_HOME) $T_TESTDATA/.zsh_plugins.zsh && echo "bundle script matches"
diff <(antidote list --url | sort) $T_TESTDATA/repo-list.txt && echo "repo list matches"
EOS
  expect "bundle script matches
repo list matches"
}

@test "zcompile compiles bundles and update recompiles them" {
  run_session <<'EOS'
(( $(ls $(antidote home)/**/*.zwc(N) | wc -l) > 50 )) && echo "zwc files compiled"
rm -rf -- $(antidote home)/**/*.zwc(N)
antidote update &>/dev/null
(( $(ls $(antidote home)/**/*.zwc(N) | wc -l) > 50 )) && echo "zwc files recompiled after update"
EOS
  expect "zwc files compiled
zwc files recompiled after update"
}

@test "branch annotations check out the requested branch" {
  run_session <<'EOS'
git -C "$ANTIDOTE_HOME/mattmc3/antidote" rev-parse --abbrev-ref HEAD 2>/dev/null
EOS
  expect "v1"
}

@test "purge --all aborts when told no" {
  SESSION_PRELUDE="$SESSION_PRELUDE
zstyle ':antidote:test:purge' answer 'n'"
  run_session <<'EOS'
antidote purge --all >/dev/null; echo "purge exit: $?"
echo "bundles remaining: $(antidote list | wc -l | tr -d ' ')"
EOS
  expect "purge exit: 1
bundles remaining: 15"
}

@test "purge --all removes everything when told yes" {
  SESSION_PRELUDE="$SESSION_PRELUDE
zstyle ':antidote:test:purge' answer 'y'"
  run_session <<'EOS'
antidote purge --all | tail -n 1
echo "bundles remaining: $(antidote list 2>/dev/null | wc -l | tr -d ' ')"
[[ ! -e $ZDOTDIR/.zsh_plugins.zsh ]] && echo "static file gone"
bak=($ZDOTDIR/.zsh_plugins.*.bak(N)) && (( $#bak )) && echo "backup created"
EOS
  expect "Antidote purge complete. Be sure to start a new Zsh session.
bundles remaining: 0
static file gone
backup created"
}

# Bundle files with CRLF line endings parse correctly.
@test "bundle a CRLF plugins file" {
  SESSION_PRELUDE=""
  run_session <<'EOS'
antidote bundle <$T_TESTDATA/.zsh_plugins.crlf.txt 2>/dev/null | subenv ANTIDOTE_HOME
EOS
  expected=$(cat <<'EOF'
fpath+=( "$ANTIDOTE_HOME/rupa/z" )
source "$ANTIDOTE_HOME/rupa/z/z.sh"
fpath+=( "$ANTIDOTE_HOME/zsh-users/zsh-syntax-highlighting" )
source "$ANTIDOTE_HOME/zsh-users/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh"
fpath+=( "$ANTIDOTE_HOME/zsh-users/zsh-completions" )
source "$ANTIDOTE_HOME/zsh-users/zsh-completions/zsh-completions.plugin.zsh"
fpath+=( "$ANTIDOTE_HOME/zsh-users/zsh-autosuggestions" )
source "$ANTIDOTE_HOME/zsh-users/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh"
fpath+=( "$ANTIDOTE_HOME/zsh-users/zsh-history-substring-search" )
source "$ANTIDOTE_HOME/zsh-users/zsh-history-substring-search/zsh-history-substring-search.plugin.zsh"
EOF
)
  expect "$expected"
}

@test "load clones and sources a real plugin" {
  SESSION_PRELUDE='echo "rupa/z" > $ZDOTDIR/.zsh_plugins.txt'
  run_session <<'EOS'
antidote load 2>&1
echo "z alias defined: $+aliases[z]"
EOS
  expect "# antidote cloning rupa/z...
z alias defined: 1"
}

@test "load regenerates the static file when the plugins file changes" {
  SESSION_PRELUDE='echo "rupa/z" > $ZDOTDIR/.zsh_plugins.txt
antidote load &>/dev/null
echo "zsh-users/zsh-completions path:src kind:fpath" >> $ZDOTDIR/.zsh_plugins.txt'
  run_session <<'EOS'
antidote load 2>&1
cat $ZDOTDIR/.zsh_plugins.zsh | subenv ANTIDOTE_HOME
(( $fpath[(Ie)$ANTIDOTE_HOME/zsh-users/zsh-completions/src] )) && echo "completions in fpath"
EOS
  expect '# antidote cloning zsh-users/zsh-completions...
fpath+=( "$ANTIDOTE_HOME/rupa/z" )
source "$ANTIDOTE_HOME/rupa/z/z.sh"
fpath+=( "$ANTIDOTE_HOME/zsh-users/zsh-completions/src" )
completions in fpath'
}
