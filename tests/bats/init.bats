#!/usr/bin/env bats
# antidote init tests

load helpers/common

setup() { antidote_common_setup; }

@test "antidote init emits the dynamic-mode function" {
  run_session <<<'antidote init | subenv ANTIDOTE_HOME ANTIDOTE_CONFIG'
  expected=$(cat <<'EOF'
#!/usr/bin/env zsh
function antidote {
  case "$1" in
    bundle)
      shift
      antidote-bundle-dynamic '$ANTIDOTE_HOME' '$ANTIDOTE_CONFIG' "$@"
      ;;
    *)
      ANTIDOTE_DYNAMIC=true antidote-dispatch $@
      ;;
  esac
}
EOF
)
  expect "$expected"
}

# antidote-init emits the script from the parent shell (no subprocess)
# when there is no config file. Guard against its resolver drifting from
# antidote.zsh: across every OS branch, parent must equal subprocess.
@test "antidote init matches the subprocess across OS branches" {
  SESSION_PRELUDE='export ANTIDOTE_CONFIG=$HOME/no/such/config.zsh
unset ANTIDOTE_HOME'
  run_session <<'EOS'
for os in darwin21.3.0 msys foobar; do
  zstyle ':antidote:test:env' OSTYPE $os
  [[ $os == msys ]] && zstyle ':antidote:test:env' LOCALAPPDATA $HOME/AppData
  parent=$(antidote init)
  sub=$(antidote-zsh init)
  [[ $parent == $sub ]] && echo "$os: match" || echo "$os: MISMATCH"
done
EOS
  assert_line "darwin21.3.0: match"
  assert_line "msys: match"
  assert_line "foobar: match"
}

# A broken ANTIDOTE_ZSH makes any subprocess call fail, so succeeding
# here proves the parent-shell path never spawned one.
@test "init needs no subprocess when there is no config file" {
  SESSION_PRELUDE='export ANTIDOTE_CONFIG=$HOME/no/such/config.zsh
echo "exit 3" >$HOME/broken.zsh
ANTIDOTE_ZSH=$HOME/broken.zsh'
  run_session <<<'antidote init | tail -n1'
  assert_success
  assert_output "}"
}

# A config file only matters here if it sets the home, so the common
# case of a config file setting something else keeps the fast path.
@test "init needs no subprocess for a config file that skips home" {
  SESSION_PRELUDE='export ANTIDOTE_CONFIG=$HOME/cfg.zsh
print -r -- "zstyle \":antidote:bundle\" path-style short" >$ANTIDOTE_CONFIG
echo "exit 3" >$HOME/broken.zsh
ANTIDOTE_ZSH=$HOME/broken.zsh'
  run_session <<<'antidote init | tail -n1'
  assert_success
  assert_output "}"
}

# The parent shell never sources the config file, so a config-file home
# has to reach the emitted script anyway.
@test "init honors a config-file home" {
  SESSION_PRELUDE='export ANTIDOTE_CONFIG=$HOME/cfg.zsh
echo "zstyle \":antidote:home\" dir /from/config" >$ANTIDOTE_CONFIG
unset ANTIDOTE_HOME
antidote-setup'
  run_session <<<'antidote init | grep antidote-bundle-dynamic | subenv HOME'
  assert_output "      antidote-bundle-dynamic '/from/config' '\$HOME/cfg.zsh' \"\$@\""
}

@test "dynamic mode clones and sources a bundle on the fly" {
  run_session <<'EOS'
source <(antidote init)
antidote bundle foo/bar
EOS
  assert_output "# antidote cloning foo/bar...
sourcing bar.plugin.zsh from foo/bar..."
}

@test "dynamic mode autoloads bundle functions" {
  run_session <<'EOS'
source <(antidote init)
antidote bundle foo/baz autoload:functions &>/dev/null
echo "baz autoloaded: $+functions[baz]"
EOS
  assert_output "baz autoloaded: 1"
}

@test "dynamic mode tracks plugins and libs arrays" {
  run_session <<'EOS'
source <(antidote init)
antidote bundle foo/bar &>/dev/null
antidote bundle foo/baz autoload:functions &>/dev/null
antidote bundle $ZDOTDIR/custom/lib &>/dev/null
echo "plugins: $#plugins libs: $#libs"
EOS
  assert_output "plugins: 2 libs: 2"
}

@test "dynamic using: context persists across calls" {
  run_session <<'EOS'
source <(antidote init)
antidote bundle using:ohmy/ohmy path:plugins &>/dev/null
antidote bundle docker
antidote bundle extract
EOS
  assert_output "sourcing plugins/docker/docker.plugin.zsh from ohmy/ohmy...
sourcing plugins/extract/extract.plugin.zsh from ohmy/ohmy..."
}

@test "dynamic using: context resets when a new using: is seen" {
  run_session <<'EOS'
source <(antidote init)
antidote bundle using:ohmy/ohmy path:plugins &>/dev/null
antidote bundle using:foo/bar &>/dev/null
antidote bundle bar.plugin.zsh
EOS
  assert_output "sourcing bar.plugin.zsh from foo/bar..."
}

@test "dynamic path-based using: loads local subplugins" {
  run_session <<'EOS'
source <(antidote init)
antidote bundle using:$ZDOTDIR/custom path:plugins
antidote bundle myplugin
antidote bundle doesnotexist 2>/dev/null
EOS
  assert_output "sourcing myplugin..."
}
