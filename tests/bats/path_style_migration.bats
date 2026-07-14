#!/usr/bin/env bats
# Path-style migration tests (ported from tests/test_path_style_migration.md).
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
@test "bundle_dir reuses clones from other path-styles" {
  migration_session <<'EOS'
escaped_dir=$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-fakegitsite.com-SLASH-foo-SLASH-bar
command mkdir -p $escaped_dir/.git
zstyle ':antidote:bundle' path-style full
bundle_dir foo/bar | subenv ANTIDOTE_HOME
test -d $ANTIDOTE_HOME/fakegitsite.com/foo/bar || echo "no full dir created"
command rm -rf $escaped_dir
short_dir=$ANTIDOTE_HOME/foo/bar
command mkdir -p $short_dir/.git
bundle_dir foo/bar | subenv ANTIDOTE_HOME
test -d $ANTIDOTE_HOME/fakegitsite.com/foo/bar || echo "no full dir created"
command rm -rf $short_dir
escaped_ssh_dir=$ANTIDOTE_HOME/git-AT-fakegitsite.com-COLON-foo-SLASH-qux
command mkdir -p $escaped_ssh_dir/.git
bundle_dir git@fakegitsite.com:foo/qux | subenv ANTIDOTE_HOME
test -d $ANTIDOTE_HOME/fakegitsite.com/foo/qux || echo "no full dir created"
command rm -rf $escaped_ssh_dir
short_dir=$ANTIDOTE_HOME/bar/baz
command mkdir -p $short_dir/.git
bundle_dir bar/baz | subenv ANTIDOTE_HOME
test -d $ANTIDOTE_HOME/fakegitsite.com/bar/baz || echo "no full dir created"
command rm -rf $short_dir
EOS
  assert_line --index 0 '$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-fakegitsite.com-SLASH-foo-SLASH-bar'
  assert_line --index 1 "no full dir created"
  assert_line --index 2 '$ANTIDOTE_HOME/foo/bar'
  assert_line --index 3 "no full dir created"
  assert_line --index 4 '$ANTIDOTE_HOME/git-AT-fakegitsite.com-COLON-foo-SLASH-qux'
  assert_line --index 5 "no full dir created"
  assert_line --index 6 '$ANTIDOTE_HOME/bar/baz'
  assert_line --index 7 "no full dir created"
  [ "${#lines[@]}" -eq 8 ]
}

# bundle_dir itself has no side effects; bundle_dir_cleanup removes
# legacy dupes when the preferred path exists.
@test "bundle_dir_cleanup removes legacy path-style duplicates" {
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
command rm -rf $full_dir
escaped_dir=$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-fakegitsite.com-SLASH-foo-SLASH-bar
short_dir=$ANTIDOTE_HOME/foo/bar
command mkdir -p $escaped_dir/.git $short_dir/.git $full_dir/.git
bundle_dir_cleanup foo/bar
test -d $full_dir && echo "preferred survives"
test -d $escaped_dir || echo "escaped removed"
test -d $short_dir || echo "short removed"
EOS
  assert_line --index 0 '$ANTIDOTE_HOME/fakegitsite.com/foo/bar'
  assert_line --index 1 "legacy clone untouched by bundle_dir"
  assert_line --index 2 "legacy clone removed"
  assert_line --index 3 "preferred clone kept"
  assert_line --index 4 "preferred survives"
  assert_line --index 5 "escaped removed"
  assert_line --index 6 "short removed"
  [ "${#lines[@]}" -eq 7 ]
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
@test "style switches reuse existing clones end to end" {
  migration_session <<'EOS'
zstyle ':antidote:bundle' path-style escaped
antidote bundle foo/bar &>/dev/null
antidote bundle bar/baz &>/dev/null
zstyle ':antidote:bundle' path-style full
antidote bundle foo/bar &>/dev/null
antidote bundle bar/baz &>/dev/null
antidote list | wc -l | awk '{print $1}'
command rm -rf $ANTIDOTE_HOME/*
zstyle ':antidote:bundle' path-style short
antidote bundle foo/bar &>/dev/null
test -d $ANTIDOTE_HOME/foo/bar && echo "short clone exists"
zstyle ':antidote:bundle' path-style full
antidote bundle foo/bar &>/dev/null
test -d $ANTIDOTE_HOME/fakegitsite.com/foo/bar || echo "no full dupe"
test -d $ANTIDOTE_HOME/foo/bar && echo "short clone kept"
command rm -rf $ANTIDOTE_HOME/*
zstyle ':antidote:bundle' path-style full
antidote bundle foo/bar &>/dev/null
test -d $ANTIDOTE_HOME/fakegitsite.com/foo/bar && echo "full clone exists"
zstyle ':antidote:bundle' path-style escaped
antidote bundle foo/bar &>/dev/null
test -d $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-fakegitsite.com-SLASH-foo-SLASH-bar || echo "no escaped dupe"
test -d $ANTIDOTE_HOME/fakegitsite.com/foo/bar && echo "full clone kept"
command rm -rf $ANTIDOTE_HOME/*
zstyle ':antidote:bundle' path-style full
antidote bundle foo/bar &>/dev/null
zstyle ':antidote:bundle' path-style short
antidote bundle foo/bar &>/dev/null
test -d $ANTIDOTE_HOME/foo/bar || echo "no short dupe"
test -d $ANTIDOTE_HOME/fakegitsite.com/foo/bar && echo "full clone kept again"
EOS
  assert_line --index 0 "2"
  assert_line --index 1 "short clone exists"
  assert_line --index 2 "no full dupe"
  assert_line --index 3 "short clone kept"
  assert_line --index 4 "full clone exists"
  assert_line --index 5 "no escaped dupe"
  assert_line --index 6 "full clone kept"
  assert_line --index 7 "no short dupe"
  assert_line --index 8 "full clone kept again"
  [ "${#lines[@]}" -eq 9 ]
}
