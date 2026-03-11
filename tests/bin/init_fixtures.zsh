#!/usr/bin/env zsh
# shellcheck disable=SC3043
setopt ERR_EXIT NO_UNSET

die()  { warn "$@"; exit "${ERR:-1}"; }
say()  { printf '%s\n' "$@"; }
warn() { say "$@" >&2; }

ROOT_DIR="$(git -C "${0:A:h}" rev-parse --show-toplevel)" \
  || ERR=2 die "Cannot locate git root for '$0'."

FIXTURE_DIR="$ROOT_DIR/tests/fixtures"
FIXTURE_SHAS_FILE="$FIXTURE_DIR/fixture_shas.tsv"

# Load the fixture SHAs from TSV file if it exists
typeset -gA fixture_shas
typeset -ga fixture_urls
if [[ -f "$FIXTURE_SHAS_FILE" ]]; then
  while IFS=$'\t' read -r key value; do
    [[ -n "$key" ]] && fixture_shas[$key]="$value"
  done < "$FIXTURE_SHAS_FILE"
fi

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
  mkdir -p "$FIXTURE_DIR"
  rm -rf -- "$FIXTURE_DIR"/bare "$FIXTURE_DIR"/antidote
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

  dir=${url:gs/\:/-COLON-}
  dir=${dir:gs/\//-SLASH-}
  dir=${dir:gs/\@/-AT-}
  say "$dir"
}

generate_fixture_shas() {
  : > "$FIXTURE_SHAS_FILE"
  for key in "${(@ko)fixture_shas}"; do
    printf '%s\t%s\n' "$key" "${fixture_shas[$key]}" >> "$FIXTURE_SHAS_FILE"
  done
  say "Generated $FIXTURE_SHAS_FILE"
}

generate_fixture_gitconfig() {
  local gitconfig_file="$FIXTURE_DIR/gitconfig"
  local url safe_dir
  : > "$gitconfig_file"
  for url in "${fixture_urls[@]}"; do
    safe_dir="$(url_to_dir "$url")"
    printf '[url "%s"]\n\tinsteadOf = %s\n' \
      "$FIXTURE_DIR/bare/$safe_dir" "$url" \
      >> "$gitconfig_file"
    # also match URLs with .git suffix to prevent double .git
    local url_dotgit="${url%.git}.git"
    if [[ "$url_dotgit" != "$url" ]]; then
      printf '[url "%s"]\n\tinsteadOf = %s\n' \
        "$FIXTURE_DIR/bare/$safe_dir" "$url_dotgit" \
        >> "$gitconfig_file"
    fi
  done
  say "Generated $gitconfig_file"
}

record_sha() {
  local short_name dir sha
  short_name="$1"
  dir="$2"
  sha="$(git -C "$dir" rev-parse --short HEAD)"
  fixture_shas[$short_name]="$sha"
  printf 'Updated %-30s SHA: %s\n' "$short_name" "$sha"
}

commit_and_record() {
  local dir sha_key commit_msg
  dir="$1"
  sha_key="$2"
  commit_msg="$3"

  touch -t 202601010000 "$dir"/**/*(..)
  git -C "$dir" add .
  git -C "$dir" commit --quiet -m "$commit_msg"
  git -C "$dir" push --quiet
  record_sha "$sha_key" "$dir"
  if [[ -n "${fixture_shas[$sha_key]:-}" ]]; then
    check_sha "$dir" "${fixture_shas[$sha_key]}"
  fi
}

get_fixture_dir() {
  local url="$1"
  say "$FIXTURE_DIR/antidote/$(url_to_clone_dir "$url")"
}

add_functions_to_fixture() {
  local url dir func_name
  url="$1"
  func_name="$2"
  dir="$FIXTURE_DIR/antidote/$(url_to_clone_dir "$url")"

  mkdir -p "$dir/functions"
  cat > "$dir/functions/$func_name" <<EOF
#!/bin/zsh
function $func_name {
  echo $func_name function
}
$func_name "\$@"
EOF
  cat > "$dir/functions/_$func_name" <<EOF
#!/bin/zsh
echo _$func_name completion
EOF
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
  local url file_extension safe_dir repo_name short_name clone_path git_bare_dir git_clone_dir
  url="$1"
  file_extension="$2"

  fixture_urls+=("$url")
  safe_dir="$(url_to_dir "$url")"
  repo_name="$(get_repo_name "$url")"
  short_name="$(get_short_name "$url")"
  clone_path="$(url_to_clone_dir "$url")"
  git_bare_dir="$FIXTURE_DIR/bare/$safe_dir"
  git_clone_dir="$FIXTURE_DIR/antidote/$clone_path"

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
echo "sourcing ${repo_name}.${file_extension} from ${short_name}..."
plugins+=($short_name)
EOF
  fi
  touch -t 202601010000 "$target"

  # Add files
  git -C "$git_clone_dir" add .
  git -C "$git_clone_dir" commit --quiet -m "Add plugin file"
  git -C "$git_clone_dir" push --quiet

  # Record and check the SHA
  record_sha "$short_name" "$git_clone_dir"
  if [[ -n "${fixture_shas[$short_name]:-}" ]]; then
    check_sha "$git_clone_dir" "${fixture_shas[$short_name]}"
  fi
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

# short_name is user/repo (e.g. "foo/bar" for https://site.com/foo/bar.git)
get_short_name() {
  local url path
  [ -n "$1" ] || return 1
  url="$1"
  url="${url%.git}"

  if [[ "$url" == https://* ]]; then
    path="${url#https://}"
    path="${path#*/}"  # strip site
  elif [[ "$url" == git@*:* ]]; then
    path="${url#git@*:}"
  else
    path="$url"
  fi
  say "$path"
}

# Convert URL to site/user/repo clone path (matches antidote's "full" path style).
url_to_clone_dir() {
  local url path
  [ -n "$1" ] || return 1
  url="$1"
  url="${url%.git}"

  if [[ "$url" == https://* ]]; then
    path="${url#https://}"
  elif [[ "$url" == git@*:* ]]; then
    path="${url#git@}"
    path="${path/://}"
  else
    path="$url"
  fi
  say "$path"
}

setup_fixture_ohmy() {
  local ohmy_url ohmy_dir ohmy_short_name
  ohmy_url="https://fakegitsite.com/ohmy/ohmy"

  # Create initial fixture
  make_fixture "$ohmy_url" "sh"

  ohmy_dir="$FIXTURE_DIR/antidote/$(url_to_clone_dir "$ohmy_url")"
  ohmy_short_name="$(get_short_name "$ohmy_url")"

  # Create lib directory with lib files
  mkdir -p "$ohmy_dir/lib"
  for i in {1..3}; do
    cat > "$ohmy_dir/lib/lib${i}.zsh" <<EOF
echo "sourcing lib/lib${i}.zsh from ${ohmy_short_name}..."
libs+=(\${ohmy_short_name}:lib${i})
EOF
  done

  # Create themes directory with theme file
  mkdir -p "$ohmy_dir/themes"
  cat > "$ohmy_dir/themes/pretty.zsh-theme" <<EOF
echo "sourcing themes/pretty.zsh-theme from ${ohmy_short_name}..."
themes+=(\${ohmy_short_name}:pretty)
EOF

  # Create custom/themes directory with theme files
  mkdir -p "$ohmy_dir/custom/themes"
  cat > "$ohmy_dir/custom/themes/pretty.zsh-theme" <<EOF
echo "sourcing custom/themes/pretty.zsh-theme from ${ohmy_short_name}..."
themes+=(\${ohmy_short_name}:pretty)
EOF
  cat > "$ohmy_dir/custom/themes/ugly.zsh-theme" <<EOF
echo "sourcing custom/themes/ugly.zsh-theme from ${ohmy_short_name}..."
themes+=(\${ohmy_short_name}:ugly)
EOF

  # Create plugins directory with plugin subdirectories
  mkdir -p "$ohmy_dir/plugins"
  for plugin in docker extract git macos magic-enter; do
    mkdir -p "$ohmy_dir/plugins/$plugin"
    cat > "$ohmy_dir/plugins/$plugin/${plugin}.plugin.zsh" <<EOF
echo "sourcing plugins/${plugin}/${plugin}.plugin.zsh from ${ohmy_short_name}..."
plugins+=(\${ohmy_short_name}:${plugin})
EOF
  done

  # Add completion for docker plugin
  cat > "$ohmy_dir/plugins/docker/_docker" <<'EOF'
#compdef
EOF

  # Add function for macos plugin
  mkdir -p "$ohmy_dir/plugins/macos/functions"
  cat > "$ohmy_dir/plugins/macos/functions/macos_func" <<'EOF'
#!/bin/zsh
function macos_func {
  echo macos_func "$@"
}
macos_func "$@"
EOF

  commit_and_record "$ohmy_dir" "ohmy/ohmy-updated" "Add lib, themes, and plugins directories"
}

setup_fixture_foo_baz() {
  local url dir
  url="https://fakegitsite.com/foo/baz"
  make_fixture "$url" "plugin.zsh"
  dir=$(get_fixture_dir "$url")
  add_functions_to_fixture "$url" "baz"
  commit_and_record "$dir" "foo/baz-updated" "Add function files"
}

setup_fixture_purify() {
  local url dir
  url="https://fakegitsite.com/themes/purify"
  make_fixture "$url" "plugin.zsh"
  dir=$(get_fixture_dir "$url")
  make_file "$dir"/purify.zsh
  make_file "$dir"/async.zsh
  make_file "$dir"/promp_purify_setup
  commit_and_record "$dir" "themes/purify-updated1" "Add more fake purify files"

  # Remove plugin file so we have a bad HEAD
  rm -rf -- "$dir"/purify.plugin.zsh
  commit_and_record "$dir" "themes/purify-updated2" "Remove plugin file"
}

setup_fixture_zsh_defer() {
  local url dir
  url="https://fakegitsite.com/getantidote/zsh-defer"
  make_fixture "$url" "plugin.zsh"
  dir=$(get_fixture_dir "$url")
  cat >> "$dir/zsh-defer.plugin.zsh" <<'EOF'

function zsh-defer {
  "$@"
}
EOF
  commit_and_record "$dir" "getantidote/zsh-defer-updated" "Add zsh-defer function"
}

setup_fixture_foo_bar() {
  local url dir
  url="https://fakegitsite.com/foo/bar"
  make_fixture "$url" "plugin.zsh"
  dir=$(get_fixture_dir "$url")

  # Create a 'dev' branch for branch annotation testing
  git -C "$dir" checkout --quiet -b dev
  git -C "$dir" push --quiet origin dev
  git -C "$dir" checkout --quiet main
}

setup_fixture_themes_ohmytheme() {
  make_fixture "https://fakegitsite.com/themes/ohmytheme" "zsh-theme"
}

# setup_fixture_zsh_users_zsh_bench() {
#   make_fixture "https://fakegitsite.com/zsh-users/zsh-bench" ""
# }

setup_fixture_foo_qux() {
  make_fixture "git@fakegitsite.com:foo/qux" "plugin.zsh"
}

setup_fixture_bar_baz() {
  make_fixture "https://fakegitsite.com/bar/baz" "plugin.zsh"
}

setup_fixture_custom_zsh_defer() {
  local url dir
  url="https://fakegitsite.com/custom/zsh-defer"
  make_fixture "$url" "plugin.zsh"
  dir=$(get_fixture_dir "$url")
  cat >> "$dir/zsh-defer.plugin.zsh" <<'EOF'

function zsh-defer {
  "$@"
}
EOF
  commit_and_record "$dir" "custom/zsh-defer-updated" "Add zsh-defer function"
}

setup_fixture_zsh_users_zsh_autosuggestions() {
  make_fixture "https://fakegitsite.com/zsh-users/zsh-autosuggestions" "plugin.zsh"
}

init_git_environment
clean

# Setup all fixtures
setup_fixture_bar_baz
setup_fixture_custom_zsh_defer
setup_fixture_foo_bar
setup_fixture_foo_baz
setup_fixture_foo_qux
setup_fixture_ohmy
setup_fixture_themes_ohmytheme
setup_fixture_purify
# setup_fixture_zsh_users_zsh_bench
setup_fixture_zsh_defer
setup_fixture_zsh_users_zsh_autosuggestions

# Generate the fixture_shas.tsv and gitconfig files
generate_fixture_shas
generate_fixture_gitconfig
