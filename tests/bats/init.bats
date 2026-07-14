#!/usr/bin/env bats
# antidote init tests (ported from tests/test_cmd_init.md)

load helpers/common

setup() { antidote_common_setup; }

@test "antidote init emits the dynamic-mode function" {
  run_session <<<'antidote init'
  expected=$(cat <<'EOF'
#!/usr/bin/env zsh
function antidote {
  case "$1" in
    bundle)
      source <( ANTIDOTE_DYNAMIC=true antidote-dispatch $@ ) || ANTIDOTE_DYNAMIC=true antidote-dispatch $@
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
