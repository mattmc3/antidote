#!/usr/bin/env zsh
0=${(%):-%x}
autoload -Uz ${0:A:h}/functions/testinit && testinit
ztap_header "${0:t:r}"

# setup
source $BASEDIR/antidote.zsh
setup_fakezdotdir script

# missing arg script command fails
() {
  local actual expected exitcode
  expected="antidote: error: bundle argument expected"
  actual=($(antidote script 2>&1)); exitcode=$?
  @test "'antidote script' fails" $exitcode -ne 0
  @test "'antidote script' prints arg error" "$expected" = "$actual"
}

# accepts '--arg val', '--arg:val', '--arg=val' syntax
() {
  local actual expected exitcode bundle bundledir args variants v
  variants=('--kind zsh' '--kind:zsh' '--kind=zsh')
  bundle="foo/bar"
  bundledir="https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar"
  expected=(
    "fpath+=( $ANTIDOTE_HOME/$bundledir )"
    "source $ANTIDOTE_HOME/$bundledir/bar.plugin.zsh"
  )
  for v in $variants; do
    IFS=' ' read -A args <<<"$v"
    actual=($(antidote script $args $bundle 2>&1)); exitcode=$?
    actual=("${(@f)actual}")
    @test "'antidote script --args' flag syntax check succeeds" $exitcode -eq 0
    @test "'antidote script' arg syntax works for '$args'" "$expected" = "$actual"
  done
}

# script a file
() {
  local actual expected bundle
  bundle="$ZDOTDIR/aliases.zsh"
  expected="source $bundle"
  actual=$(antidote script $bundle)
  @test "the bundle is a file" -f "$bundle"
  @test "'antidote script file' works" "$expected" = "$actual"
}

# script lib directory
() {
  local actual expected bundle
  bundle="$ZDOTDIR/zshrc.d"
  expected=(
    "fpath+=( $bundle )"
    "source $bundle/conf1.zsh"
    "source $bundle/conf2.zsh"
  )
  actual=("${(@f)$(antidote script $bundle)}")
  @test "the bundle is a directory" -d "$bundle"
  @test "'antidote script lib' works" "$expected" = "$actual"
}

# script a plugin directory
() {
  local actual expected bundle bundledir
  bundle="$ZDOTDIR/custom/plugins/myplugin"
  expected=(
    "fpath+=( $bundle )"
    "source $bundle/${bundle:t}.plugin.zsh"
  )
  actual=("${(@f)$(antidote script $bundle)}")
  @test "'antidote script dir' works" "$expected" = "$actual"
}

# script repo
() {
  local actual expected bundle bundles bundledir
  bundles=(
    foo/bar
    https://github.com/foo/bar
    https://github.com/foo/bar.git
    git@github.com:bar/baz.git
  )
  for bundle in $bundles; do
    if [[ $bundle = git@* ]]; then
      bundledir="git-AT-github.com-COLON-bar-SLASH-baz"
    else
      bundledir="https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar"
    fi
    expected=(
      "fpath+=( $ANTIDOTE_HOME/$bundledir )"
      "source $ANTIDOTE_HOME/$bundledir/${${bundle:t}%.git}.plugin.zsh"
    )
    actual=("${(@f)$(antidote script $bundle)}")
    @test "'antidote script $bundle' works" "$expected" = "$actual"
  done
}

#region antidote script with annotations
# script --kind clone
() {
  local actual expected bundle bundledir args
  args=(--kind clone)
  bundle="foo/bar"
  expected=
  actual=("${(@f)$(antidote script $args $bundle)}")
  @test "'antidote script $args $bundle' works" "$expected" = "$actual"
}

# script --kind zsh
() {
  local actual expected bundle bundledir args
  args=(--kind zsh)
  bundle="foo/bar"
  bundledir="https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar"
  expected=(
    "fpath+=( $ANTIDOTE_HOME/$bundledir )"
    "source $ANTIDOTE_HOME/$bundledir/bar.plugin.zsh"
  )
  actual=("${(@f)$(antidote script $args $bundle)}")
  @test "'antidote script $args $bundle' works" "$expected" = "$actual"
}

# script --kind fpath
() {
  local actual expected bundle bundledir args
  args=(--kind fpath)
  bundle="foo/bar"
  bundledir="https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar"
  expected=(
    "fpath+=( $ANTIDOTE_HOME/$bundledir )"
  )
  actual=("${(@f)$(antidote script $args $bundle)}")
  @test "'antidote script $args $bundle' works" "$expected" = "$actual"
}

# script --kind path
() {
  local actual expected bundle bundledir args
  args=(--kind path)
  bundle="foo/bar"
  bundledir="https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar"
  expected=(
    "export PATH=\"$ANTIDOTE_HOME/$bundledir:\$PATH\""
  )
  actual=("${(@f)$(antidote script $args $bundle)}")
  @test "'antidote script $args $bundle' works" "$expected" = "$actual"
}

# script --kind defer
() {
  local actual expected bundle bundledir args
  args=(--kind defer)
  bundle="foo/bar"
  bundledir="https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar"
  expected=(
    "fpath+=( $ANTIDOTE_HOME/$bundledir )"
    "zsh-defer source $ANTIDOTE_HOME/$bundledir/bar.plugin.zsh"
  )
  actual=("${(@f)$(antidote script $args $bundle)}")
  @test "'antidote script $args $bundle' works" "$expected" = "$actual"
}

# script --kind defer with zstyle
() {
  local actual expected bundle bundledir args
  zstyle ':antidote:plugin:*' defer-options '-a'
  zstyle ':antidote:plugin:foo/bar' defer-options '-p'
  args=(--kind defer)

  bundle="foo/bar"
  bundledir="https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar"
  expected=(
    "fpath+=( $ANTIDOTE_HOME/$bundledir )"
    "zsh-defer -p source $ANTIDOTE_HOME/$bundledir/bar.plugin.zsh"
  )
  actual=("${(@f)$(antidote script $args $bundle)}")
  @test "'antidote script $args $bundle' works" "$expected" = "$actual"

  bundle="baz/qux"
  bundledir="https-COLON--SLASH--SLASH-github.com-SLASH-baz-SLASH-qux"
  expected=(
    "fpath+=( $ANTIDOTE_HOME/$bundledir )"
    "zsh-defer -a source $ANTIDOTE_HOME/$bundledir/qux.plugin.zsh"
  )
  actual=("${(@f)$(antidote script $args $bundle)}")
  @test "'antidote script $args $bundle' works" "$expected" = "$actual"
}

# script --path plugin
() {
  local actual expected bundle bundledir args
  args=(--path plugins/extract)
  bundle="ohmyzsh/ohmyzsh"
  bundledir="https-COLON--SLASH--SLASH-github.com-SLASH-ohmyzsh-SLASH-ohmyzsh/plugins/extract"
  expected=(
    "fpath+=( $ANTIDOTE_HOME/$bundledir )"
    "source $ANTIDOTE_HOME/$bundledir/extract.plugin.zsh"
  )
  actual=("${(@f)$(antidote script $args $bundle)}")
  @test "'antidote script $args $bundle' works" "$expected" = "$actual"
}

# script --path file
() {
  local actual expected bundle bundledir args
  args=(--path lib/lib1.zsh)
  bundle="ohmyzsh/ohmyzsh"
  bundledir="https-COLON--SLASH--SLASH-github.com-SLASH-ohmyzsh-SLASH-ohmyzsh/lib"
  expected=(
    "source $ANTIDOTE_HOME/$bundledir/lib1.zsh"
  )
  actual=("${(@f)$(antidote script $args $bundle)}")
  @test "'antidote script $args $bundle' works" "$expected" = "$actual"
}

# script --path libdir
() {
  local actual expected bundle bundledir args
  args=(--path lib)
  bundle="ohmyzsh/ohmyzsh"
  bundledir="https-COLON--SLASH--SLASH-github.com-SLASH-ohmyzsh-SLASH-ohmyzsh/lib"
  expected=(
    "fpath+=( $ANTIDOTE_HOME/$bundledir )"
    "source $ANTIDOTE_HOME/$bundledir/lib1.zsh"
    "source $ANTIDOTE_HOME/$bundledir/lib2.zsh"
    "source $ANTIDOTE_HOME/$bundledir/lib3.zsh"
  )
  actual=("${(@f)$(antidote script $args $bundle)}")
  @test "'antidote script $args $bundle' works" "$expected" = "$actual"
}

# script --path theme
() {
  local actual expected bundle bundledir args
  args=(--path custom/themes/pure)
  bundle="ohmyzsh/ohmyzsh"
  bundledir="https-COLON--SLASH--SLASH-github.com-SLASH-ohmyzsh-SLASH-ohmyzsh/custom/themes/pure"
  expected=(
    "fpath+=( $ANTIDOTE_HOME/$bundledir )"
    "source $ANTIDOTE_HOME/$bundledir/pure.zsh-theme"
  )
  actual=("${(@f)$(antidote script $args $bundle)}")
  @test "'antidote script $args $bundle' theme works" "$expected" = "$actual"
}
#endregion

ztap_footer

# teardown
ZDOTDIR=$OLD_ZDOTDIR
