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
escaped_dir=$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-fakegitsite.com-SLASH-foo-SLASH-bar
command mkdir -p $escaped_dir/.git
zstyle ':antidote:bundle' path-style full
bundle_dir foo/bar | subenv ANTIDOTE_HOME
test -d $ANTIDOTE_HOME/fakegitsite.com/foo/bar || echo "no full dir created"
EOS
  assert_line --index 0 '$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-fakegitsite.com-SLASH-foo-SLASH-bar'
  assert_line --index 1 "no full dir created"
  [ "${#lines[@]}" -eq 2 ]
}

@test "bundle_dir reuses a short-style clone" {
  migration_session <<'EOS'
short_dir=$ANTIDOTE_HOME/foo/bar
command mkdir -p $short_dir/.git
zstyle ':antidote:bundle' path-style full
bundle_dir foo/bar | subenv ANTIDOTE_HOME
test -d $ANTIDOTE_HOME/fakegitsite.com/foo/bar || echo "no full dir created"
EOS
  assert_line --index 0 '$ANTIDOTE_HOME/foo/bar'
  assert_line --index 1 "no full dir created"
  [ "${#lines[@]}" -eq 2 ]
}

@test "bundle_dir reuses an escaped-style ssh clone" {
  migration_session <<'EOS'
escaped_ssh_dir=$ANTIDOTE_HOME/git-AT-fakegitsite.com-COLON-foo-SLASH-qux
command mkdir -p $escaped_ssh_dir/.git
zstyle ':antidote:bundle' path-style full
bundle_dir git@fakegitsite.com:foo/qux | subenv ANTIDOTE_HOME
test -d $ANTIDOTE_HOME/fakegitsite.com/foo/qux || echo "no full dir created"
EOS
  assert_line --index 0 '$ANTIDOTE_HOME/git-AT-fakegitsite.com-COLON-foo-SLASH-qux'
  assert_line --index 1 "no full dir created"
  [ "${#lines[@]}" -eq 2 ]
}

# bundle_dir itself has no side effects; bundle_dir_cleanup removes
# legacy dupes when the preferred path exists.
@test "bundle_dir_cleanup removes a legacy escaped duplicate" {
  migration_session <<'EOS'
escaped_dir=$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-fakegitsite.com-SLASH-foo-SLASH-bar
full_dir=$ANTIDOTE_HOME/fakegitsite.com/foo/bar
command mkdir -p $escaped_dir/.git $full_dir/.git
zstyle ':antidote:bundle' path-style full
bundle_dir foo/bar | subenv ANTIDOTE_HOME
test -d $escaped_dir && echo "legacy clone untouched by bundle_dir"
bundle_dir_cleanup foo/bar
test -d $escaped_dir || echo "legacy clone removed"
test -d $full_dir && echo "preferred clone kept"
EOS
  assert_line --index 0 '$ANTIDOTE_HOME/fakegitsite.com/foo/bar'
  assert_line --index 1 "legacy clone untouched by bundle_dir"
  assert_line --index 2 "legacy clone removed"
  assert_line --index 3 "preferred clone kept"
  [ "${#lines[@]}" -eq 4 ]
}

@test "bundle_dir_cleanup removes every legacy style at once" {
  migration_session <<'EOS'
escaped_dir=$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-fakegitsite.com-SLASH-foo-SLASH-bar
short_dir=$ANTIDOTE_HOME/foo/bar
full_dir=$ANTIDOTE_HOME/fakegitsite.com/foo/bar
command mkdir -p $escaped_dir/.git $short_dir/.git $full_dir/.git
zstyle ':antidote:bundle' path-style full
bundle_dir_cleanup foo/bar
test -d $full_dir && echo "preferred survives"
test -d $escaped_dir || echo "escaped removed"
test -d $short_dir || echo "short removed"
EOS
  assert_line --index 0 "preferred survives"
  assert_line --index 1 "escaped removed"
  assert_line --index 2 "short removed"
  [ "${#lines[@]}" -eq 3 ]
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
test -d $ANTIDOTE_HOME/foo/bar && echo "short clone exists"
zstyle ':antidote:bundle' path-style full
antidote bundle foo/bar &>/dev/null
test -d $ANTIDOTE_HOME/fakegitsite.com/foo/bar || echo "no full dupe"
test -d $ANTIDOTE_HOME/foo/bar && echo "short clone kept"
EOS
  assert_line --index 0 "short clone exists"
  assert_line --index 1 "no full dupe"
  assert_line --index 2 "short clone kept"
  [ "${#lines[@]}" -eq 3 ]
}

@test "escaped re-bundle reuses a full-style clone" {
  migration_session <<'EOS'
zstyle ':antidote:bundle' path-style full
antidote bundle foo/bar &>/dev/null
test -d $ANTIDOTE_HOME/fakegitsite.com/foo/bar && echo "full clone exists"
zstyle ':antidote:bundle' path-style escaped
antidote bundle foo/bar &>/dev/null
test -d $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-fakegitsite.com-SLASH-foo-SLASH-bar || echo "no escaped dupe"
test -d $ANTIDOTE_HOME/fakegitsite.com/foo/bar && echo "full clone kept"
EOS
  assert_line --index 0 "full clone exists"
  assert_line --index 1 "no escaped dupe"
  assert_line --index 2 "full clone kept"
  [ "${#lines[@]}" -eq 3 ]
}

@test "short re-bundle reuses a full-style clone" {
  migration_session <<'EOS'
zstyle ':antidote:bundle' path-style full
antidote bundle foo/bar &>/dev/null
zstyle ':antidote:bundle' path-style short
antidote bundle foo/bar &>/dev/null
test -d $ANTIDOTE_HOME/foo/bar || echo "no short dupe"
test -d $ANTIDOTE_HOME/fakegitsite.com/foo/bar && echo "full clone kept"
EOS
  assert_line --index 0 "no short dupe"
  assert_line --index 1 "full clone kept"
  [ "${#lines[@]}" -eq 2 ]
}
