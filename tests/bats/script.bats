#!/usr/bin/env bats
# antidote zsh_script tests (ported from tests/test_cmd_script.md)

load helpers/common

setup() { antidote_common_setup; }

@test "zsh_script requires a bundle argument" {
  fixture_session <<<'antidote __private__ zsh_script 2>&1'
  assert_failure 1
  assert_output "antidote: error: bundle argument expected"
}

# zsh_script accepts flat key-value pairs as an assoc array.
@test "zsh_script validates kind values" {
  fixture_session <<'EOS'
antidote __private__ zsh_script __bundle__ foo/bar kind zsh >/dev/null; echo "kind zsh exit: $?"
antidote __private__ zsh_script __bundle__ foo/bar >/dev/null; echo "no kind exit: $?"
antidote __private__ zsh_script __bundle__ foo/bar kind badkind 2>&1
EOS
  assert_line "kind zsh exit: 0"
  assert_line "no kind exit: 0"
  assert_line "antidote: error: unexpected kind value: 'badkind'"
}

# zsh_script works with local files and directories as well as repos.
@test "zsh_script handles local files, lib dirs, and plugin dirs" {
  fixture_session <<'EOS'
antidote __private__ zsh_script __bundle__ $ZDOTDIR/aliases.zsh | subenv ZDOTDIR
antidote __private__ zsh_script __bundle__ $ZDOTDIR/custom/lib | subenv ZDOTDIR
antidote __private__ zsh_script __bundle__ $ZDOTDIR/custom/plugins/myplugin | subenv ZDOTDIR
EOS
  expected=$(cat <<'EOF'
source "$ZDOTDIR/aliases.zsh"
fpath+=( "$ZDOTDIR/custom/lib" )
source "$ZDOTDIR/custom/lib/lib1.zsh"
source "$ZDOTDIR/custom/lib/lib2.zsh"
fpath+=( "$ZDOTDIR/custom/plugins/myplugin" )
source "$ZDOTDIR/custom/plugins/myplugin/myplugin.plugin.zsh"
EOF
)
  expect "$expected"
}

@test "zsh_script handles repos in escaped path-style" {
  fixture_session <<'EOS'
zstyle ':antidote:bundle' path-style escaped
ANTIDOTE_HOME=$HOME/.cache/antibody
antidote __private__ zsh_script __bundle__ foo/bar 2>/dev/null | subenv ANTIDOTE_HOME
antidote __private__ zsh_script __bundle__ https://fakegitsite.com/foo/bar | subenv ANTIDOTE_HOME
antidote __private__ zsh_script __bundle__ https://fakegitsite.com/foo/bar.git | subenv ANTIDOTE_HOME
antidote __private__ zsh_script __bundle__ git@fakegitsite.com:foo/qux.git 2>/dev/null | subenv ANTIDOTE_HOME
EOS
  expect "$(cat "$PRJDIR/tests/testdata/antibody/script-foobar.zsh" "$PRJDIR/tests/testdata/antibody/script-foobar.zsh" "$PRJDIR/tests/testdata/antibody/script-foobar.zsh" "$PRJDIR/tests/testdata/antibody/script-fooqux.zsh")"
}

# kind:clone does nothing when the plugin exists, clones when missing.
@test "kind:clone clones only when missing" {
  fixture_session <<'EOS'
antidote __private__ zsh_script __bundle__ foo/bar kind clone
antidote __private__ zsh_script __bundle__ themes/ohmytheme kind clone
EOS
  assert_output "# antidote cloning themes/ohmytheme..."
}

@test "kind zsh, path, fpath, and autoload script output" {
  fixture_session <<'EOS'
antidote __private__ zsh_script __bundle__ foo/bar kind zsh | subenv ANTIDOTE_HOME
antidote __private__ zsh_script __bundle__ foo/bar kind path | subenv ANTIDOTE_HOME
antidote __private__ zsh_script __bundle__ foo/bar kind fpath | subenv ANTIDOTE_HOME
antidote __private__ zsh_script __bundle__ $ZDOTDIR/functions kind autoload | subenv ZDOTDIR
EOS
  expected=$(cat <<'EOF'
fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/foo/bar" )
source "$ANTIDOTE_HOME/fakegitsite.com/foo/bar/bar.plugin.zsh"
export PATH="$ANTIDOTE_HOME/fakegitsite.com/foo/bar:$PATH"
fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/foo/bar" )
fpath+=( "$ZDOTDIR/functions" )
builtin autoload -Uz $fpath[-1]/*(N.:t)
EOF
)
  expect "$expected"
}

@test "kind:defer loads zsh-defer first unless skipped" {
  fixture_session <<'EOS'
antidote __private__ zsh_script __bundle__ foo/bar kind defer | subenv ANTIDOTE_HOME
antidote __private__ zsh_script __bundle__ foo/bar kind defer __skip_load_defer__ 1 | subenv ANTIDOTE_HOME
EOS
  expected=$(cat <<'EOF'
if ! (( $+functions[zsh-defer] )); then
  fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/getantidote/zsh-defer" )
  source "$ANTIDOTE_HOME/fakegitsite.com/getantidote/zsh-defer/zsh-defer.plugin.zsh"
fi
fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/foo/bar" )
zsh-defer source "$ANTIDOTE_HOME/fakegitsite.com/foo/bar/bar.plugin.zsh"
fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/foo/bar" )
zsh-defer source "$ANTIDOTE_HOME/fakegitsite.com/foo/bar/bar.plugin.zsh"
EOF
)
  expect "$expected"
}

# defer-options zstyles: pattern zstyles apply per-bundle.
@test "defer-options zstyles customize zsh-defer flags" {
  fixture_session <<'EOS'
zstyle ':antidote:bundle:*' defer-options '-a'
zstyle ':antidote:bundle:foo/bar' defer-options '-p'
antidote __private__ zsh_script __bundle__ foo/bar kind defer | subenv ANTIDOTE_HOME
antidote __private__ zsh_script __bundle__ bar/baz kind defer | subenv ANTIDOTE_HOME
EOS
  expected=$(cat <<'EOF'
if ! (( $+functions[zsh-defer] )); then
  fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/getantidote/zsh-defer" )
  source "$ANTIDOTE_HOME/fakegitsite.com/getantidote/zsh-defer/zsh-defer.plugin.zsh"
fi
fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/foo/bar" )
zsh-defer -p source "$ANTIDOTE_HOME/fakegitsite.com/foo/bar/bar.plugin.zsh"
if ! (( $+functions[zsh-defer] )); then
  fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/getantidote/zsh-defer" )
  source "$ANTIDOTE_HOME/fakegitsite.com/getantidote/zsh-defer/zsh-defer.plugin.zsh"
fi
fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/bar/baz" )
zsh-defer -a source "$ANTIDOTE_HOME/fakegitsite.com/bar/baz/baz.plugin.zsh"
EOF
)
  expect "$expected"
}

@test "path: annotation handles plugin dirs, files, lib dirs, and themes" {
  fixture_session <<'EOS'
antidote __private__ zsh_script __bundle__ ohmy/ohmy path plugins/extract | subenv ANTIDOTE_HOME
antidote __private__ zsh_script __bundle__ ohmy/ohmy path lib/lib1.zsh | subenv ANTIDOTE_HOME
antidote __private__ zsh_script __bundle__ ohmy/ohmy path lib | subenv ANTIDOTE_HOME
antidote __private__ zsh_script __bundle__ ohmy/ohmy path themes/pretty.zsh-theme | subenv ANTIDOTE_HOME
EOS
  expected=$(cat <<'EOF'
fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy/plugins/extract" )
source "$ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy/plugins/extract/extract.plugin.zsh"
source "$ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy/lib/lib1.zsh"
fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy/lib" )
source "$ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy/lib/lib1.zsh"
source "$ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy/lib/lib2.zsh"
source "$ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy/lib/lib3.zsh"
source "$ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy/themes/pretty.zsh-theme"
EOF
)
  expect "$expected"
}

@test "conditional wraps output and autoload precedes sourcing" {
  fixture_session <<'EOS'
antidote __private__ zsh_script __bundle__ ohmy/ohmy path plugins/macos conditional is-macos | subenv ANTIDOTE_HOME
antidote __private__ zsh_script __bundle__ ohmy/ohmy path plugins/macos autoload functions | subenv ANTIDOTE_HOME
EOS
  expected=$(cat <<'EOF'
if is-macos; then
  fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy/plugins/macos" )
  source "$ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy/plugins/macos/macos.plugin.zsh"
fi
fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy/plugins/macos/functions" )
builtin autoload -Uz $fpath[-1]/*(N.:t)
fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy/plugins/macos" )
source "$ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy/plugins/macos/macos.plugin.zsh"
EOF
)
  expect "$expected"
}

@test "fpath-rule append, prepend, and rejection" {
  fixture_session <<'EOS'
antidote __private__ zsh_script __bundle__ ohmy/ohmy path plugins/docker fpath-rule append | subenv ANTIDOTE_HOME
antidote __private__ zsh_script __bundle__ ohmy/ohmy path plugins/docker fpath-rule prepend | subenv ANTIDOTE_HOME
antidote __private__ zsh_script __bundle__ ohmy/ohmy path plugins/docker fpath-rule foobar 2>&1
EOS
  expected=$(cat <<'EOF'
fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy/plugins/docker" )
source "$ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy/plugins/docker/docker.plugin.zsh"
fpath=( "$ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy/plugins/docker" $fpath )
source "$ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy/plugins/docker/docker.plugin.zsh"
antidote: error: unexpected fpath rule: 'foobar'
EOF
)
  expect "$expected"
}

# If a plugin is deferred, so is its post event; conditional wraps the
# entire deferred block.
@test "pre/post functions, including deferred and conditional variants" {
  fixture_session <<'EOS'
antidote __private__ zsh_script __bundle__ foo/bar pre run_before | subenv ANTIDOTE_HOME
antidote __private__ zsh_script __bundle__ foo/bar post run_after | subenv ANTIDOTE_HOME
antidote __private__ zsh_script __bundle__ foo/bar kind defer pre pre-event post post-event | subenv ANTIDOTE_HOME
antidote __private__ zsh_script __bundle__ foo/bar kind defer conditional is-macos | subenv ANTIDOTE_HOME
antidote __private__ zsh_script __bundle__ foo/bar conditional is-macos pre setup post cleanup | subenv ANTIDOTE_HOME
EOS
  expected=$(cat <<'EOF'
run_before
fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/foo/bar" )
source "$ANTIDOTE_HOME/fakegitsite.com/foo/bar/bar.plugin.zsh"
fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/foo/bar" )
source "$ANTIDOTE_HOME/fakegitsite.com/foo/bar/bar.plugin.zsh"
run_after
pre-event
if ! (( $+functions[zsh-defer] )); then
  fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/getantidote/zsh-defer" )
  source "$ANTIDOTE_HOME/fakegitsite.com/getantidote/zsh-defer/zsh-defer.plugin.zsh"
fi
fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/foo/bar" )
zsh-defer source "$ANTIDOTE_HOME/fakegitsite.com/foo/bar/bar.plugin.zsh"
zsh-defer post-event
if is-macos; then
  if ! (( $+functions[zsh-defer] )); then
    fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/getantidote/zsh-defer" )
    source "$ANTIDOTE_HOME/fakegitsite.com/getantidote/zsh-defer/zsh-defer.plugin.zsh"
  fi
  fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/foo/bar" )
  zsh-defer source "$ANTIDOTE_HOME/fakegitsite.com/foo/bar/bar.plugin.zsh"
fi
if is-macos; then
  setup
  fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/foo/bar" )
  source "$ANTIDOTE_HOME/fakegitsite.com/foo/bar/bar.plugin.zsh"
  cleanup
fi
EOF
)
  expect "$expected"
}

# initfiles picks the best init file by precedence, one type at a time.
@test "initfiles precedence and failure cases" {
  run_session <<'EOS'
PLUGINDIR=$T_TEMPDIR/initfiles/myplugin
mkdir -p $PLUGINDIR/lib
touch $PLUGINDIR/myplugin.plugin.zsh $PLUGINDIR/whatever.plugin.zsh
touch $PLUGINDIR/file.zsh $PLUGINDIR/file.sh $PLUGINDIR/file.bash
touch $PLUGINDIR/mytheme.zsh-theme $PLUGINDIR/README.md $PLUGINDIR/file
touch $PLUGINDIR/lib/lib1.zsh $PLUGINDIR/lib/lib2.zsh $PLUGINDIR/lib/lib3.zsh
antidote __private__ initfiles $PLUGINDIR | subenv PLUGINDIR
rm $PLUGINDIR/myplugin.plugin.zsh
antidote __private__ initfiles $PLUGINDIR | subenv PLUGINDIR
rm $PLUGINDIR/whatever.plugin.zsh
antidote __private__ initfiles $PLUGINDIR | subenv PLUGINDIR
rm $PLUGINDIR/file.zsh
antidote __private__ initfiles $PLUGINDIR | subenv PLUGINDIR
rm $PLUGINDIR/file.sh
antidote __private__ initfiles $PLUGINDIR | subenv PLUGINDIR
antidote __private__ initfiles $PLUGINDIR/lib | subenv PLUGINDIR
rm $PLUGINDIR/mytheme.zsh-theme
antidote __private__ initfiles $PLUGINDIR; echo "no match exit: $?"
mkdir -p $T_TEMPDIR/initfiles/foo
antidote __private__ initfiles $T_TEMPDIR/initfiles/foo; echo "empty exit: $?"
EOS
  expected=$(cat <<'EOF'
$PLUGINDIR/myplugin.plugin.zsh
$PLUGINDIR/whatever.plugin.zsh
$PLUGINDIR/file.zsh
$PLUGINDIR/file.sh
$PLUGINDIR/mytheme.zsh-theme
$PLUGINDIR/lib/lib1.zsh
$PLUGINDIR/lib/lib2.zsh
$PLUGINDIR/lib/lib3.zsh
no match exit: 1
empty exit: 1
EOF
)
  expect "$expected"
}
