#!/usr/bin/env bash
# shellcheck disable=SC3043

die()  { warn "$@"; exit "${ERR:-1}"; }
say()  { printf '%s\n' "$@"; }
warn() { say "$@" >&2; }

ROOT_DIR="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)" \
  || ERR=2 die "Cannot locate git root for '$0'."

FIXTURE_DIR="$ROOT_DIR/tests/fixtures"

init_git_environment() {
  # Ignore user/system git configs to keep commits deterministic.
  export GIT_CONFIG_GLOBAL=/dev/null
  export GIT_CONFIG_NOSYSTEM=1

  export GIT_AUTHOR_NAME="Fixture Author"
  export GIT_AUTHOR_EMAIL="fixture@example.com"
  export GIT_AUTHOR_DATE="2025-01-01T00:00:00Z"

  export GIT_COMMITTER_NAME="Fixture Committer"
  export GIT_COMMITTER_EMAIL="fixture@example.com"
  export GIT_COMMITTER_DATE="2025-01-01T00:00:00Z"
}

clean() {
  cd "$FIXTURE_DIR" || die "Cannot locate fixture dir '$FIXTURE_DIR'."
  for dir in bare clone; do
    [ -d "$FIXTURE_DIR/$dir" ] && rm -rf -- "${FIXTURE_DIR:?}/$dir"
  done
}

url_to_dir() {
  local url dir
  [ -n "$1" ] || return 1

  # Ensure the provided URL ends with .git
  url="$1"
  case "$url" in
    *.git) ;;
    *) url="${url}.git" ;;
  esac

  dir=$(printf '%s' "$url" | sed -e 's/:/-COLON-/g' -e 's/\//-SLASH-/g' -e 's/@/-AT-/g')
  say "$dir"
}

# shellcheck disable=SC2016
make_file() {
  local file
  file="$1"
  printf '%s\n' '#!/bin/zsh' > "$file"
  printf '%s\n' '0=${(%):-%x}' >> "$file"
  printf '%s\n' 'echo "${0:a:t}"' >> "$file"
}

make_fixture() {
  local url file_extension safe_dir repo_name git_bare_dir git_clone_dir
  local expected_short_sha
  url="$1"
  file_extension="$2"
  expected_short_sha="$3"

  safe_dir="$(url_to_dir "$url")"
  repo_name="$(get_repo_name "$url")"
  git_bare_dir="$FIXTURE_DIR/bare/$safe_dir"
  git_clone_dir="$FIXTURE_DIR/clone/$repo_name"

  # Make a bare repo and clone it.
  git init --quiet --bare -b main "$git_bare_dir"
  # git -C "$git_bare_dir" remote add "origin" "$url"
  git clone --quiet "$git_bare_dir" "$git_clone_dir" >/dev/null 2>&1

  # Make a plugin file.
  if [ "$file_extension" = "" ]; then
    target="$git_clone_dir/${repo_name}"
    cat > "$target" <<EOF
#!/bin/zsh
printf '%s\n' "executing ${repo_name}..."
EOF
  else
    target="$git_clone_dir/${repo_name}.${file_extension}"
    cat > "$target" <<EOF
echo "sourcing ${repo_name}.${file_extension}..."
loaded_plugins+=("$repo_name")
EOF
  fi
  touch -t 202501010000 "$target"

  # Add files
  git -C "$git_clone_dir" add .
  git -C "$git_clone_dir" commit --quiet -m "Add plugin file"
  git -C "$git_clone_dir" push --quiet

  # Asserts
  check_sha "$git_clone_dir" "$expected_short_sha"
  printf 'Created %-10s SHA: %s\n' "$repo_name" "$(git -C "$git_clone_dir" rev-parse --short HEAD)"
}

check_sha() {
  local dir expected_sha
  dir="$1"
  expected_sha="$2"
  actual_sha="$(git -C "$dir" rev-parse --short HEAD)"
  test "$expected_sha" = "$actual_sha" \
    || warn "Unexpected SHA for '$dir'. Expecting '$expected_sha'. Actual '$actual_sha'."
}

# repo_name contains the last element (e.g. "bar" for .../foo/bar.git)
get_repo_name() {
  local url name
  [ -n "$1" ] || return 1
  url="$1"

  # Extract last path element and strip trailing .git
  name="${url##*/}"
  name="${name%.git}"
  printf '%s\n' "$name"
}

init_git_environment
clean

make_fixture "https://fakegitsite.com/foo/bar" "plugin.zsh" "5cbf3a2"
make_fixture "git@fakegitsite.com:foo/baz" "plugin.zsh" "76a7fe4"
make_fixture "https://fakegitsite.com/ohmy/ohmy" "sh" "336333d"
make_fixture "https://fakegitsite.com/themes/ohmytheme" "zsh-theme" "1f4580c"
make_fixture "https://fakegitsite.com/themes/purify" "plugin.zsh" "121d0f0"
make_fixture "https://fakegitsite.com/zsh-users/zsh-bench" "" "b2569f3"
make_fixture "https://fakegitsite.com/getantidote/zsh-defer" "plugin.zsh" "1d0c4a0"

# Update purify with more files
purify_dir="$FIXTURE_DIR"/clone/purify
purify_repo_name="$(get_repo_name "$purify_dir")"
make_file "$purify_dir"/purify.zsh
make_file "$purify_dir"/async.zsh
make_file "$purify_dir"/promp_purify_setup
git -C "$purify_dir" add .
git -C "$purify_dir" commit --quiet -m "Add more fake purify files"
git -C "$purify_dir" push --quiet
check_sha "$purify_dir" "0b1ea0e"
printf 'Updated %-10s SHA: %s\n' "$purify_repo_name" "$(git -C "$purify_dir" rev-parse --short HEAD)"

# Remove plugin file so we have a bad HEAD
rm -rf -- "$purify_dir"/purify.plugin.zsh
git -C "$purify_dir" add .
git -C "$purify_dir" commit --quiet -m "Add more fake purify files"
git -C "$purify_dir" push --quiet
check_sha "$purify_dir" "8ab107c"
printf 'Updated %-10s SHA: %s\n' "$purify_repo_name" "$(git -C "$purify_dir" rev-parse --short HEAD)"
