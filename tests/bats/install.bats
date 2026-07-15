#!/usr/bin/env bats
# antidote install tests (ported from tests/test_cmd_install.md)

load helpers/common

setup() { antidote_common_setup; }

install_session() {
  SESSION_PRELUDE='antidote bundle <$ZDOTDIR/.base_test_fixtures.txt &>/dev/null' \
    run_session
}

@test "install requires a bundle argument" {
  install_session <<'EOS'
antidote install 2>&1
EOS
  assert_failure 1
  assert_output "antidote: error: required argument 'bundle' not provided, try --help"
}

@test "installing an existing bundle fails" {
  install_session <<'EOS'
antidote install foo/bar &>/dev/null; echo "exit: $?"
antidote install foo/bar 2>&1 | subenv HOME
EOS
  assert_line --index 0 "exit: 1"
  assert_line --index 1 'antidote: error: foo/bar already installed: $HOME/.cache/antidote/fakegitsite.com/foo/bar'
}

# The clone failure emits git error details with variable temp paths,
# so assert only the stable lines. (The clitest original checked exit
# code only.)
@test "installing a non-existent bundle fails" {
  install_session <<'EOS'
antidote install does-not/exist &>/dev/null; echo "exit: $?"
antidote install does-not/exist 2>&1 >/dev/null
EOS
  assert_line "exit: 1"
  assert_line "# antidote: unable to install bundle 'does-not/exist'."
}

@test "install clones and appends to the plugins file" {
  install_session <<'EOS'
antidote install themes/purify | subenv ZDOTDIR
tail -n 1 $ZDOTDIR/.zsh_plugins.txt
EOS
  expected=$(cat <<'EOF'
# antidote cloning themes/purify...
Adding bundle to '$ZDOTDIR/.zsh_plugins.txt':
themes/purify
themes/purify
EOF
)
  expect "$expected"
}

@test "install with --kind and --conditional" {
  install_session <<'EOS'
antidote install --kind fpath --conditional is-macos themes/ohmytheme | subenv ZDOTDIR
tail -n 1 $ZDOTDIR/.zsh_plugins.txt
EOS
  expected=$(cat <<'EOF'
# antidote cloning themes/ohmytheme...
Adding bundle to '$ZDOTDIR/.zsh_plugins.txt':
themes/ohmytheme kind:fpath conditional:is-macos
themes/ohmytheme kind:fpath conditional:is-macos
EOF
)
  expect "$expected"
}

@test "install with all annotation flags" {
  install_session <<'EOS'
antidote install --path lib --autoload functions --pre setup_func --post teardown_func --pin 367eaa595eb776634c100cec24f241cc2256e79e test/install | subenv ZDOTDIR
tail -n 1 $ZDOTDIR/.zsh_plugins.txt
EOS
  expected=$(cat <<'EOF'
# antidote cloning test/install...
Adding bundle to '$ZDOTDIR/.zsh_plugins.txt':
test/install path:lib autoload:functions pre:setup_func post:teardown_func pin:367eaa595eb776634c100cec24f241cc2256e79e
test/install path:lib autoload:functions pre:setup_func post:teardown_func pin:367eaa595eb776634c100cec24f241cc2256e79e
EOF
)
  expect "$expected"
}
