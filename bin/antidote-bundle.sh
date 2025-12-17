#!/usr/bin/env dash
# shellcheck disable=SC3043

antidote_script() {
  local lineno="$1"
  shift
  printf '%s script: %s\n' "$lineno" "$@"
}

antidote_bundle() {
  local bundle line lineno
  if [ $# -gt 0 ]; then
    lineno=0
    for bundle in "$@"; do
      printf '%b' "$bundle" | tr -d "\r" | while IFS= read -r line || [ -n "$line" ]; do
        # printf 'Bundle %s\n' "$line"
        lineno=$((lineno + 1))
        antidote_script "$lineno" "$line"
      done
    done
  elif [ ! -t 0 ]; then
    lineno=0
    while IFS= read -r line || [ -n "$line" ]; do
      lineno=$((lineno + 1))
      antidote_script "$lineno" "$line"
    done
  fi

  # elif [[ ! -t 0 ]]; then
  #   local data
  #   while IFS= read -r data || [[ -n "$data" ]]; do
  #     input+=("$data")
  #   done
  # fi
  # printf '%s\n' "${input[@]}"
}
antidote_bundle "$@"
