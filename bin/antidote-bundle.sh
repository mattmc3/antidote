#!/usr/bin/env dash
# shellcheck disable=SC3043

THIS_SCRIPT="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
PARSER_SCRIPT="$(dirname "$THIS_SCRIPT")"/antidote_dsl_parser.zsh
TAB="$(printf '\t')"

ensure_cloned() {
  local arg
  echo "Ensuring cloned... $*"
  for arg; do
    echo "   arg: $arg"
  done
}

emit_zsh_script() {
  local arg
  echo "Emmitting Zsh script... $*"
  for arg; do
    echo "   arg: $arg"
  done
}

parse_dsl() {
  zsh "$PARSER_SCRIPT"
}

# Usage: bundle_apply <command> < input.tsv
# For each TSV line, splits fields into "$@" and calls: command "$@"
bundle_apply() {
  cmd=$1
  while IFS= read -r line; do
    # shellcheck disable=SC2086
    IFS=$TAB set -- $line
    "$cmd" "$@"
  done
}

antidote_bundle() {
  local bundles

  bundles="$({
    [ $# -eq 0 ] || printf '%b\n' "$*"
    [ -t 0 ] || cat
  })"

  printf '%s\n' "$bundles" |
    parse_dsl |
    bundle_apply ensure_cloned

  printf '%s\n' "$bundles" |
    parse_dsl |
    bundle_apply emit_zsh_script
}
antidote_bundle "$@"
