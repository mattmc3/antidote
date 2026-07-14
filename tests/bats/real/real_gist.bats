#!/usr/bin/env bats
# Real gist bundle tests (ported from tests/test_real_gist.md).
# Network test — run via `just test-real`.

load ../helpers/common

setup() {
  antidote_common_setup
  SESSION_SETUP=t_setup_real
}

# Gist URLs have a single path segment (no user/repo), and should be
# treated as valid URL bundles.
@test "bundle, path, and list a gist URL" {
  run_session <<'EOS'
antidote bundle https://gist.github.com/mattmc3/6bc5646ae0fb7cc86502933ca6661d5c.git 2>&1 | head -1
antidote path https://gist.github.com/mattmc3/6bc5646ae0fb7cc86502933ca6661d5c.git | subenv ANTIDOTE_HOME
antidote list --url | grep gist
EOS
  expected=$(cat <<'EOF'
# antidote cloning mattmc3/6bc5646ae0fb7cc86502933ca6661d5c...
$ANTIDOTE_HOME/mattmc3/6bc5646ae0fb7cc86502933ca6661d5c
https://gist.github.com/mattmc3/6bc5646ae0fb7cc86502933ca6661d5c.git
EOF
)
  expect "$expected"
}
