#!/usr/bin/env bats
# Alternative zsh-defer repo (ported from tests/test_alt_zsh_defer_bundle.md).
# If the user forks zsh-defer, support setting a zstyle for an
# alternative repo location.

load helpers/common

setup() { antidote_common_setup; }

@test "defer bundle honors the :antidote:defer bundle zstyle" {
  run_session <<'EOS'
zstyle ':antidote:bundle' path-style short
zstyle ':antidote:defer' bundle 'custom/zsh-defer'
antidote bundle 'zsh-users/zsh-autosuggestions kind:defer' 2>/dev/null | subenv HOME
EOS
  expected=$(cat <<'EOF'
if ! (( $+functions[zsh-defer] )); then
  fpath+=( "$HOME/.cache/antidote/custom/zsh-defer" )
  source "$HOME/.cache/antidote/custom/zsh-defer/zsh-defer.plugin.zsh"
fi
fpath+=( "$HOME/.cache/antidote/zsh-users/zsh-autosuggestions" )
zsh-defer source "$HOME/.cache/antidote/zsh-users/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh"
EOF
)
  expect "$expected"
}
