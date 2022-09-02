#!/usr/bin/env zsh
0=${(%):-%x}
autoload -Uz ${0:A:h}/functions/testinit && testinit
ztap_header "${0:t:r}"

# setup
source $BASEDIR/antidote.zsh

# mocks
function git {
  # handle these commands:
  # - `git clone --quiet --depth 1 --recurse-submodules --shallow-submodules --branch branch $url $dir`
  local args=("$@[@]")
  local o_path o_quiet o_depth o_recurse_submodules o_shallow_submodules o_branch
  zparseopts -D -E --                        \
    C:=o_path                                \
    -quiet=o_quiet                           \
    -recurse-submodules=o_recurse_submodules \
    -shallow-submodules=o_shallow_submodules \
    -depth:=o_depth                          \
    -branch:=o_branch                        ||
    return 1

  if [[ "$1" = "clone" ]]; then
    local giturl="$2"
    local bundledir="$3"
    src="$FAKEZDOTDIR/antidote_home/${bundledir:t}"
    if [[ -d $src ]]; then
      cp -r $src ${bundledir:h}
    elif ! (( $#o_quiet )); then
      echo "FAKEGIT: Cloning into '${url:t}'..."
      echo "FAKEGIT: Repository not found."
      echo "FAKEGIT: repository '$url' not found"
    fi
  else
    echo >&2 "mocking failed for git command: git $@"
    return 1
  fi
}

() {
  local actual expected exitcode

  setup_emptyzdotdir "install"
  local bundle="foo/bar"
  local bundledir="$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar"
  local bundlefile="$ZDOTDIR/.zsh_plugins.txt"

  @test ".zsh_plugins.txt does not exist" ! -e $bundlefile
  @test "bundle '${bundledir:t}' dir does not exist" ! -e $bundledir

  expected=(
    "# antidote cloning foo/bar..."
    "Bundle '$bundle' added to '$bundlefile'."
  )
  actual=($(antidote install $bundle 2>&1)); exitcode=$?
  actual=("${(@f)actual}")

  @test "'antidote install $bundle' succeeded" $exitcode -eq 0
  @test "'antidote install $bundle' output correct" "$expected" = "$actual"

  @test "bundle '${bundledir:t}' dir exists" -e $bundledir
  @test ".zsh_plugins.txt exists" -e $bundlefile

  expected=( 'foo/bar' )
  actual=("${(f)"$(<$bundlefile)"}")
  @test "bundle file contains newly installed bundle" "$expected" = "$actual"

  # install a second bundle
  bundle="git@github.com:bar/baz"
  bundledir="$ANTIDOTE_HOME/git-AT-github.com-COLON-bar-SLASH-baz"
  @test "bundle '${bundledir:t}' dir does not exist" ! -e $bundledir
  antidote install $bundle &>/dev/null; exitcode=$?
  @test "bundle '${bundledir:t}' dir exists" -e $bundledir
  expected=(
    'foo/bar'
    'git@github.com:bar/baz'
  )
  actual=("${(f)"$(<$bundlefile)"}")
  @test "bundle file contains newly installed bundle" "$expected" = "$actual"

  # teardown
  ZDOTDIR=$OLD_ZDOTDIR
}

ztap_footer
