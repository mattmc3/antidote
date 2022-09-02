#!/usr/bin/env zsh
0=${(%):-%x}
autoload -Uz ${0:A:h}/functions/testinit && testinit
ztap_header "${0:t:r}"

# setup
source $BASEDIR/antidote.zsh
setup_fakezdotdir list

# mocks
function git {
  # handle `git -C "$dir" config remote.origin.url`
  local args=("$@[@]")
  local o_path
  zparseopts -D -- C:=o_path || return 1
  if [[ "$@" != "config remote.origin.url" ]]; then
    echo >&2 "mocking failed for git command: git $args"
    return 1
  fi
  # un-sanitize dir into URL
  local url=$o_path[-1]
  url=${url:t}
  url=${url:gs/-AT-/\@}
  url=${url:gs/-COLON-/\:}
  url=${url:gs/-SLASH-/\/}
  echo "$url"
}

# list short
() {
  local actual expected exitcode
  expected=(
    "foo/bar"
    "git@github.com:bar/baz"
    "ohmyzsh/ohmyzsh"
    "romkatv/zsh-defer"
  )
  actual=($(antidote list --short)); exitcode=$?
  @test "'antidote list --short' succeeds" "$?" -eq 0
  @test "'antidote list --short' output correct" "$actual" = "$expected"
}

# list dirs
() {
  local actual expected exitcode
  expected=(
    "$ANTIDOTE_HOME/git-AT-github.com-COLON-bar-SLASH-baz"
    "$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar"
    "$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmyzsh-SLASH-ohmyzsh"
    "$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-romkatv-SLASH-zsh-defer"
  )
  actual=($(antidote list --dirs)); exitcode=$?
  @test "'antidote list --dirs' succeeds" "$?" -eq 0
  @test "'antidote list --dirs' output correct" "$actual" = "$expected"
}

# list
() {
  local actual expected exitcode
  expected=(
    "git@github.com:bar/baz"               "$ANTIDOTE_HOME/git-AT-github.com-COLON-bar-SLASH-baz"
    "https://github.com/foo/bar"           "$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar"
    "https://github.com/ohmyzsh/ohmyzsh"   "$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmyzsh-SLASH-ohmyzsh"
    "https://github.com/romkatv/zsh-defer" "$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-romkatv-SLASH-zsh-defer"
  )
  actual=($(antidote list)); exitcode=$?
  @test "'antidote list' succeeds" "$?" -eq 0
  @test "'antidote list' output correct" "$actual" = "$expected"
}

ztap_footer

# teardown
unfunction git
