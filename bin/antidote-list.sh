#!/usr/bin/env dash
# shellcheck disable=SC3043

ANTIDOTE_HOME="$HOME/Library/Caches/antibody"
ANTIDOTE_HOME="$HOME/Library/Caches/antidote"

say()          { printf '%s\n' "$@"; }
git_basedir()  { gitcmd -C "$1" rev-parse --show-toplevel; }
git_url()      { gitcmd -C "$1" config remote.origin.url; }
git_branch()   { gitcmd -C "$1" rev-parse --abbrev-ref HEAD; }
git_sha()      { gitcmd -C "$1" rev-parse HEAD; }
git_repodate() { gitcmd -C "$1" log -1 --format=%cd --date=short; }

gitcmd() {
  local result err
  result="$("${ANTIDOTE_GITCMD:-git}" "$@" 2>&1)"
  err=$?
  if [ "$err" -ne 0 ]; then
    if [ -n "$result" ]; then
      warn "antidote: unexpected git error on command 'git $*'."
      warn "antidote: error details:"
      warn "$result"
      return $err
    fi
  fi
  say "$result"
}

list_bundle_dirs() {
  local d1 d2
  for d1 in "$ANTIDOTE_HOME"/*; do
    if [ -d "$d1/.git" ]; then
      printf '%s\n' "$d1"
    else
      for d2 in "$d1"/*; do
        [ -d "$d2/.git" ] || continue
        printf '%s\n' "$d2"
      done
    fi
  done
}

# Convert git URLs to user/repo format.
bundle_short() {
  local str last second_last

  str="${1%/}"             # strip trailing /
  str="${str%.git}"        # strip trailing .git
  str="${str#*:}"          # strip prefix (eg: git@gitsite.com:)
  last="${str##*/}"        # last part
  second_last="${str%/*}"  # second to last part
  second_last="${second_last##*/}"
  say "$second_last/$last"
}

antidote_list() {
  local dir branch sha url repo_date short_repo

  list_bundle_dirs | while IFS= read -r dir; do
    branch="$(git_branch "$dir")"
    sha="$(git_sha "$dir")"
    url="$(git_url "$dir")"
    repo_date="$(git_repodate "$dir")"
    short_repo="$(bundle_short "$url")"

    say "$short_repo"
    say "====================================================="
    say "Dir:         $dir"
    say "Branch:      $branch"
    say "SHA:         $sha"
    say "URL:         $url"
    say "Last Commit: $repo_date"
    say
  done
}

# bundle_dirs "$ANTIDOTE_HOME"

antidote_list "$@"
# bundle_short "https://github.com/zsh-users/zsh-autosuggestions"
# bundle_short "https://github.com/zsh-users/zsh-autosuggestions.git"
# bundle_short "https://github.com/zsh-users/zsh-autosuggestions/"
# bundle_short "git@github.com:zsh-users/zsh-autosuggestions"
# bundle_short "git@github.com:zsh-users/zsh-autosuggestions.git"
# bundle_short "git@github.com:zsh-users/zsh-autosuggestions/"
