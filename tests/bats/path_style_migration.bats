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
  expected=$(cat <<'EOF'
$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-fakegitsite.com-SLASH-foo-SLASH-bar
no full dir created
$ANTIDOTE_HOME/foo/bar
no full dir created
$ANTIDOTE_HOME/git-AT-fakegitsite.com-COLON-foo-SLASH-qux
no full dir created
$ANTIDOTE_HOME/bar/baz
no full dir created
EOF
)
  expect "$expected"
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
  expected=$(cat <<'EOF'
$ANTIDOTE_HOME/fakegitsite.com/foo/bar
legacy clone untouched by bundle_dir
legacy clone removed
preferred clone kept
preferred survives
escaped removed
short removed
EOF
)
  expect "$expected"
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
  expected=$(cat <<'EOF'
$ANTIDOTE_HOME/fakegitsite.com/foo/bar
$ANTIDOTE_HOME/foo/bar
$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-fakegitsite.com-SLASH-foo-SLASH-bar
EOF
)
  expect "$expected"
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
  expected=$(cat <<'EOF'
2
short clone exists
no full dupe
short clone kept
full clone exists
no escaped dupe
full clone kept
no short dupe
full clone kept again
EOF
)
  expect "$expected"
}
