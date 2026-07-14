#!/usr/bin/env bats
# Real snapshot tests (network — run via `just test-real`).
#
# Unit tests (tests/bats/snapshot.bats) cover snapshot mechanics
# against local fixtures. This only verifies what needs real GitHub:
# restoring committed snapshot files pins real repos to real SHAs, and
# pinned repos survive a real update.

load ../helpers/common

OMZ_2024=fa770f9678477febe0ed99566d9f3331f3714eca
AUTOSUGGEST_2024=11d17e7fea9fba8067f992b3d95e884c20a4069c
AUTOSUGGEST_2026=85919cd1ffa7d2d5412f6d3fe437ebdbeeec4fc5

setup() {
  antidote_common_setup
  SESSION_SETUP=t_setup_real
  SESSION_PRELUDE='zstyle ":antidote:snapshot" dir $HOME/.antidote-real-snaps
zstyle ":antidote:test:version" show-sha off
zstyle ":antidote:test:git" autostash off
antidote snapshot restore $T_TESTDATA/.zsh_plugins.snapshot.2024.txt &>/dev/null'
}

@test "restore clones real repos at the snapshotted SHAs" {
  run_session <<'EOS'
echo "ohmyzsh: $(git -C $ANTIDOTE_HOME/ohmyzsh/ohmyzsh rev-parse HEAD)"
echo "autosuggestions: $(git -C $ANTIDOTE_HOME/zsh-users/zsh-autosuggestions rev-parse HEAD)"
EOS
  expect "ohmyzsh: $OMZ_2024
autosuggestions: $AUTOSUGGEST_2024"
}

@test "restore moves repos between snapshotted points in time" {
  run_session <<'EOS'
antidote snapshot restore $T_TESTDATA/.zsh_plugins.snapshot.2026.txt &>/dev/null
echo "autosuggestions: $(git -C $ANTIDOTE_HOME/zsh-users/zsh-autosuggestions rev-parse HEAD)"
EOS
  expect "autosuggestions: $AUTOSUGGEST_2026"
}

@test "update skips a pinned repo and moves the rest" {
  SESSION_PRELUDE="$SESSION_PRELUDE
git -C \$ANTIDOTE_HOME/ohmyzsh/ohmyzsh config antidote.pin $OMZ_2024"
  run_session <<'EOS'
antidote update --bundles 2>&1 | grep -c 'skipping update for pinned bundle: ohmyzsh/ohmyzsh'
echo "ohmyzsh: $(git -C $ANTIDOTE_HOME/ohmyzsh/ohmyzsh rev-parse HEAD)"
[[ "$(git -C $ANTIDOTE_HOME/zsh-users/zsh-autosuggestions rev-parse HEAD)" != "11d17e7fea9fba8067f992b3d95e884c20a4069c" ]] && echo "unpinned repos updated"
EOS
  expect "1
ohmyzsh: $OMZ_2024
unpinned repos updated"
}

@test "snapshot save records pins, and restore honors them" {
  SESSION_PRELUDE="$SESSION_PRELUDE
git -C \$ANTIDOTE_HOME/ohmyzsh/ohmyzsh config antidote.pin $OMZ_2024
antidote update --bundles &>/dev/null
antidote snapshot save >/dev/null
snap=\$(ls \$HOME/.antidote-real-snaps/snapshot-*.txt | tail -1)"
  run_session <<'EOS'
grep ohmyzsh $snap
antidote snapshot restore $T_TESTDATA/.zsh_plugins.snapshot.2026.txt &>/dev/null
antidote snapshot restore $snap &>/dev/null
echo "ohmyzsh restored: $(git -C $ANTIDOTE_HOME/ohmyzsh/ohmyzsh rev-parse HEAD)"
EOS
  expect "ohmyzsh/ohmyzsh kind:clone pin:$OMZ_2024
ohmyzsh restored: $OMZ_2024"
}
