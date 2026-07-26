#!/usr/bin/env bats
# Path-style migration tests.
# When upgrading from v1 (escaped path-style) to v2 (full path-style),
# existing clones should be reused rather than duplicated. See #245.

load helpers/common

setup() { antidote_common_setup; }

migration_session() {
  SESSION_PRELUDE='function bundle_dir() { antidote __private__ bundle_dir "$@"; }
function bundle_dir_cleanup() { antidote __private__ bundle_dir_cleanup "$@"; }' \
    run_session
}

# If a clone already exists under a different path-style, bundle_dir
# returns it instead of computing a new path.
@test "bundle_dir reuses an escaped-style clone" {
  migration_session <<'EOS'
command mkdir -p $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-fakegitsite.com-SLASH-foo-SLASH-bar/.git
zstyle ':antidote:bundle' path-style full
bundle_dir foo/bar | subenv ANTIDOTE_HOME
clone_dirs
EOS
  expect '$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-fakegitsite.com-SLASH-foo-SLASH-bar
https-COLON--SLASH--SLASH-fakegitsite.com-SLASH-foo-SLASH-bar'
}

@test "bundle_dir reuses a short-style clone" {
  migration_session <<'EOS'
command mkdir -p $ANTIDOTE_HOME/foo/bar/.git
zstyle ':antidote:bundle' path-style full
bundle_dir foo/bar | subenv ANTIDOTE_HOME
clone_dirs
EOS
  expect '$ANTIDOTE_HOME/foo/bar
foo/bar'
}

@test "bundle_dir reuses an escaped-style ssh clone" {
  migration_session <<'EOS'
command mkdir -p $ANTIDOTE_HOME/git-AT-fakegitsite.com-COLON-foo-SLASH-qux/.git
zstyle ':antidote:bundle' path-style full
bundle_dir git@fakegitsite.com:foo/qux | subenv ANTIDOTE_HOME
clone_dirs
EOS
  expect '$ANTIDOTE_HOME/git-AT-fakegitsite.com-COLON-foo-SLASH-qux
git-AT-fakegitsite.com-COLON-foo-SLASH-qux'
}

# bundle_dir itself has no side effects; bundle_dir_cleanup removes
# legacy dupes when the preferred path exists.
@test "bundle_dir_cleanup removes a legacy escaped duplicate" {
  migration_session <<'EOS'
command mkdir -p \
  $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-fakegitsite.com-SLASH-foo-SLASH-bar/.git \
  $ANTIDOTE_HOME/fakegitsite.com/foo/bar/.git
zstyle ':antidote:bundle' path-style full
bundle_dir foo/bar | subenv ANTIDOTE_HOME
clone_dirs
bundle_dir_cleanup foo/bar
clone_dirs
EOS
  expect '$ANTIDOTE_HOME/fakegitsite.com/foo/bar
fakegitsite.com/foo/bar
https-COLON--SLASH--SLASH-fakegitsite.com-SLASH-foo-SLASH-bar
fakegitsite.com/foo/bar'
}

@test "bundle_dir_cleanup removes every legacy style at once" {
  migration_session <<'EOS'
command mkdir -p \
  $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-fakegitsite.com-SLASH-foo-SLASH-bar/.git \
  $ANTIDOTE_HOME/foo/bar/.git \
  $ANTIDOTE_HOME/fakegitsite.com/foo/bar/.git
zstyle ':antidote:bundle' path-style full
bundle_dir_cleanup foo/bar
clone_dirs
EOS
  expect 'fakegitsite.com/foo/bar'
}

# When no clone exists under any style, the current path-style is used.
@test "new clones use the current path-style" {
  migration_session <<'EOS'
zstyle ':antidote:bundle' path-style full
bundle_dir foo/bar | subenv ANTIDOTE_HOME
zstyle ':antidote:bundle' path-style short
bundle_dir foo/bar | subenv ANTIDOTE_HOME
zstyle ':antidote:bundle' path-style escaped
bundle_dir foo/bar | subenv ANTIDOTE_HOME
EOS
  assert_line --index 0 '$ANTIDOTE_HOME/fakegitsite.com/foo/bar'
  assert_line --index 1 '$ANTIDOTE_HOME/foo/bar'
  assert_line --index 2 '$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-fakegitsite.com-SLASH-foo-SLASH-bar'
  [ "${#lines[@]}" -eq 3 ]
}

# Simulate a v1 user upgrading to v2 - antidote list should not show
# dupes, and each direction of style switch reuses the original clone.
@test "list shows no dupes after an escaped-to-full switch" {
  migration_session <<'EOS'
zstyle ':antidote:bundle' path-style escaped
antidote bundle foo/bar &>/dev/null
antidote bundle bar/baz &>/dev/null
zstyle ':antidote:bundle' path-style full
antidote bundle foo/bar &>/dev/null
antidote bundle bar/baz &>/dev/null
antidote list | wc -l | awk '{print $1}'
EOS
  assert_output "2"
}

@test "full re-bundle reuses a short-style clone" {
  migration_session <<'EOS'
zstyle ':antidote:bundle' path-style short
antidote bundle foo/bar &>/dev/null
clone_dirs
zstyle ':antidote:bundle' path-style full
antidote bundle foo/bar &>/dev/null
clone_dirs
EOS
  expect 'foo/bar
foo/bar'
}

@test "escaped re-bundle reuses a full-style clone" {
  migration_session <<'EOS'
zstyle ':antidote:bundle' path-style full
antidote bundle foo/bar &>/dev/null
clone_dirs
zstyle ':antidote:bundle' path-style escaped
antidote bundle foo/bar &>/dev/null
clone_dirs
EOS
  expect 'fakegitsite.com/foo/bar
fakegitsite.com/foo/bar'
}

@test "short re-bundle reuses a full-style clone" {
  migration_session <<'EOS'
zstyle ':antidote:bundle' path-style full
antidote bundle foo/bar &>/dev/null
zstyle ':antidote:bundle' path-style short
antidote bundle foo/bar &>/dev/null
clone_dirs
EOS
  expect 'fakegitsite.com/foo/bar'
}
