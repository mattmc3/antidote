#!/usr/bin/env zsh
0=${(%):-%x}
autoload -Uz ${0:A:h}/functions/testinit && testinit
ztap_header "${0:t:r}"

# setup
source $BASEDIR/antidote.zsh
setup_fakezdotdir update

# mocks
function git {
  # handle these commands:
  # - `git -C "$dir" config remote.origin.url`
  # - `git -C "$dir" pull --quiet --ff --rebase --autostash`
  # - `git -C "$dir" rev-parse --short HEAD`
  local args=("$@[@]")
  local o_path o_quiet o_ff o_rebase o_autostash o_short
  zparseopts -D -E --      \
    C:=o_path              \
    -short=o_short         \
    -quiet=o_quiet         \
    -ff=o_ff               \
    -rebase=o_rebase       \
    -autostash=o_autostash ||
    return 1

  if [[ "$@" = "config remote.origin.url" ]]; then
    # un-sanitize dir into URL
    local url=$o_path[-1]
    url=${url:t}
    url=${url:gs/-AT-/\@}
    url=${url:gs/-COLON-/\:}
    url=${url:gs/-SLASH-/\/}
    echo "$url"
  elif [[ "$@" = "pull" ]]; then
    (( $#o_quiet )) || echo "FAKEGIT: Already up to date."
  elif [[ "$@" = "rev-parse HEAD" ]]; then
    echo "a123456"
  else
    echo >&2 "mocking failed for git command: git $@"
    return 1
  fi
}

() {
  antidote update -h &>/dev/null
  @test "'antidote update -h' succeeds" "$?" -eq 0
}

# antidote update
() {
  local actual expected
  expected=(
    "Updating bundles..."
    "antidote: checking for updates: git@github.com:bar/baz"
    "antidote: checking for updates: https://github.com/foo/bar"
    "antidote: checking for updates: https://github.com/ohmyzsh/ohmyzsh"
    "antidote: checking for updates: https://github.com/romkatv/zsh-defer"
    "Waiting for bundle updates to complete..."
    "Bundle updates complete."
    "Updating antidote..."
    "Antidote self-update complete."
    ""
    "$(antidote --version 2>&1)"
  )
  actual=("$(antidote update $bundle)"); exitcode=$?
  actual=("${(@f)actual}")
  @test "'antidote update' succeeds" $exitcode -eq 0
  @test "'antidote update' works" "$expected" = "$actual"
}

ztap_footer

# teardown
ZDOTDIR=$OLD_ZDOTDIR
unfunction git
