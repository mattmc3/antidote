#!/usr/bin/env zsh
0=${(%):-%x}
autoload -Uz ${0:A:h}/functions/testinit && testinit
ztap_header "${0:t:r}"

# setup
ZSHDIR=$BASEDIR/tests/fakezdotdir
function git {
  @echo mockgit "$@"
}
ANTIDOTE_HOME=$BASEDIR/tests/fakezdotdir/antidote_home
source $BASEDIR/antidote.zsh

# empty bundle command succeeds
() {
  antidote bundle &>/dev/null
  @test "'antidote bundle' succeeds" $? -eq 0
}

# bundle file
() {
  local actual expected bundle
  bundle="$ZSHDIR/aliases.zsh"
  expected="source $bundle"
  actual=$(antidote bundle $bundle)
  @test "the bundle is a file" -f "$bundle"
  @test "bundle file '$bundle'" "$expected" = "$actual"
}

# bundle lib directory
() {
  local actual expected bundle
  bundle="$ZSHDIR/zshrc.d"
  expected=(
    "fpath+=( $bundle )"
    "source $bundle/conf1.zsh"
    "source $bundle/conf2.zsh"
  )
  actual=("${(@f)$(antidote bundle $bundle)}")
  @test "the bundle is a directory" -d "$bundle"
  @test "bundle lib directory: '$bundle'" "$expected" = "$actual"
}

# bundle plugin directory
() {
  local actual expected bundle bundledir
  bundle="$ZSHDIR/custom/plugins/myplugin"
  expected=(
    "fpath+=( $bundle )"
    "source $bundle/${bundle:t}.plugin.zsh"
  )
  actual=("${(@f)$(antidote bundle $bundle)}")
  @test "bundle plugin directory: '$bundle'" "$expected" = "$actual"
}

# bundle shortrepo
() {
  local actual expected bundle bundledir
  bundle="foo/bar"
  bundledir="https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar"
  expected=(
    "fpath+=( $ANTIDOTE_HOME/$bundledir )"
    "source $ANTIDOTE_HOME/$bundledir/${bundle:t}.plugin.zsh"
  )
  actual=("${(@f)$(antidote bundle $bundle)}")
  @test "bundle shortrepo: '$bundle'" "$expected" = "$actual"
}

# bundle url
() {
  local actual expected bundle bundles bundledir
  bundles=(
    https://github.com/foo/bar
    https://github.com/foo/bar.git
    git@github.com:bar/baz.git
  )
  for bundle in $bundles; do
    if [[ $bundle = http* ]]; then
      bundledir="https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar"
    else
      bundledir="git-AT-github.com-COLON-bar-SLASH-baz"
    fi
    expected=(
      "fpath+=( $ANTIDOTE_HOME/$bundledir )"
      "source $ANTIDOTE_HOME/$bundledir/${${bundle:t}%.git}.plugin.zsh"
    )
    actual=("${(@f)$(antidote bundle $bundle)}")
    @test "bundle url: '$bundle'" "$expected" = "$actual"
  done
}

# bundle annotation kind:clone
() {
  local actual expected bundle bundledir
  bundle="foo/bar kind:clone"
  bundledir="https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar"
  expected=
  actual=("${(@f)$(antidote bundle $bundle)}")
  @test "bundle annotation kind:clone: '$bundle'" "$expected" = "$actual"
}

# bundle annotation kind:zsh
() {
  local actual expected bundle bundledir
  bundle="foo/bar kind:zsh"
  bundledir="https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar"
  expected=(
    "fpath+=( $ANTIDOTE_HOME/$bundledir )"
    "source $ANTIDOTE_HOME/$bundledir/bar.plugin.zsh"
  )
  actual=("${(@f)$(antidote bundle $bundle)}")
  @test "bundle annotation kind:zsh: '$bundle'" "$expected" = "$actual"
}

# bundle annotation kind:fpath
() {
  local actual expected bundle bundledir
  bundle="foo/bar kind:fpath"
  bundledir="https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar"
  expected=(
    "fpath+=( $ANTIDOTE_HOME/$bundledir )"
  )
  actual=("${(@f)$(antidote bundle $bundle)}")
  @test "bundle annotation kind:fpath: '$bundle'" "$expected" = "$actual"
}

# bundle annotation kind:path
() {
  local actual expected bundle bundledir
  bundle="foo/bar kind:path"
  bundledir="https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar"
  expected=(
    "export PATH=\"$ANTIDOTE_HOME/$bundledir:\$PATH\""
  )
  actual=("${(@f)$(antidote bundle $bundle)}")
  @test "bundle annotation kind:path: '$bundle'" "$expected" = "$actual"
}

# bundle annotation kind:defer
() {
  local actual expected bundle bundledir
  bundle="foo/bar kind:defer"
  defer_dir='https-COLON--SLASH--SLASH-github.com-SLASH-romkatv-SLASH-zsh-defer'
  foobar_dir='https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar'
  expected=(
    "if ! (( \$+functions[zsh-defer] )); then"
    "  fpath+=( \$ANTIDOTE_HOME/$defer_dir )"
    "  source \$ANTIDOTE_HOME/$defer_dir/zsh-defer.plugin.zsh"
    "fi"
   "fpath+=( \$ANTIDOTE_HOME/$foobar_dir )"
   "zsh-defer source \$ANTIDOTE_HOME/$foobar_dir/bar.plugin.zsh"
  )
  actual=("${(@f)$(antidote bundle $bundle)}")
  actual=("$(echo $actual | sed "s|$ANTIDOTE_HOME|\$ANTIDOTE_HOME|g")")
  @test "bundle annotation kind:defer: '$bundle'" "$expected" = "$actual"
}

# bundle annotation path:plugin
() {
  local actual expected bundle bundledir
  bundle="ohmyzsh/ohmyzsh path:plugins/extract"
  bundledir="https-COLON--SLASH--SLASH-github.com-SLASH-ohmyzsh-SLASH-ohmyzsh/plugins/extract"
  expected=(
    "fpath+=( $ANTIDOTE_HOME/$bundledir )"
    "source $ANTIDOTE_HOME/$bundledir/extract.plugin.zsh"
  )
  actual=("${(@f)$(antidote bundle $bundle)}")
  @test "bundle annotation path:plugin: '$bundle'" "$expected" = "$actual"
}

# bundle annotation path:file
() {
  local actual expected bundle bundledir
  bundle="ohmyzsh/ohmyzsh path:lib/lib1.zsh"
  bundledir="https-COLON--SLASH--SLASH-github.com-SLASH-ohmyzsh-SLASH-ohmyzsh/lib"
  expected=(
    "source $ANTIDOTE_HOME/$bundledir/lib1.zsh"
  )
  actual=("${(@f)$(antidote bundle $bundle)}")
  @test "bundle annotation path:file: '$bundle'" "$expected" = "$actual"
}

# bundle annotation path:libdir
() {
  local actual expected bundle bundledir
  bundle="ohmyzsh/ohmyzsh path:lib"
  bundledir="https-COLON--SLASH--SLASH-github.com-SLASH-ohmyzsh-SLASH-ohmyzsh/lib"
  expected=(
    "fpath+=( $ANTIDOTE_HOME/$bundledir )"
    "source $ANTIDOTE_HOME/$bundledir/lib1.zsh"
    "source $ANTIDOTE_HOME/$bundledir/lib2.zsh"
    "source $ANTIDOTE_HOME/$bundledir/lib3.zsh"
  )
  actual=("${(@f)$(antidote bundle $bundle)}")
  @test "bundle annotation path:libdir: '$bundle'" "$expected" = "$actual"
}

# bundle zsh-theme
() {
  local actual expected bundle bundledir
  bundle="ohmyzsh/ohmyzsh path:custom/themes/pure"
  bundledir="https-COLON--SLASH--SLASH-github.com-SLASH-ohmyzsh-SLASH-ohmyzsh/custom/themes/pure"
  expected=(
    "fpath+=( $ANTIDOTE_HOME/$bundledir )"
    "source $ANTIDOTE_HOME/$bundledir/pure.zsh-theme"
  )
  actual=("${(@f)$(antidote bundle $bundle)}")
  @test "bundle zsh-theme: '$bundle'" "$expected" = "$actual"
}

# full bundling with redirection
() {
  local expected actual exitcode
  local pluginsfile staticfile expectedfile diffout repodirs branched_plugin

  setup_fakezdotdir bundle2
  source $BASEDIR/antidote.zsh
  pluginsfile=${ZDOTDIR:-~}/.zsh_plugins.txt
  staticfile=${ZDOTDIR:-~}/.zsh_plugins.zsh
  expectedfile=$FAKEZDOTDIR/.zsh_plugins_expected.zsh

  @test "static cache file does not exist" ! -f "$staticfile"
  antidote bundle <$pluginsfile >$staticfile 2>/dev/null
  exitcode=$?
  @test "redirection: 'antidote bundle <~/.zsh_plugins.txt >~/.zsh_plugins.zsh' succeeds!" $exitcode -eq 0

  sed -i '' "s|$ANTIDOTE_HOME|\$ANTIDOTE_HOME|g" $staticfile
  diffout=$(diff $staticfile $expectedfile)
  @test "'antidote bundle' redirection: static file diff succeeds" $exitcode -eq 0
  @test "'antidote bundle' redirection: static file diff shows no differences" -z "$diffout"
}

ztap_footer
