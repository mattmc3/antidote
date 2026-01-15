#!/bin/zsh
normalize_aarr() {
  emulate -L zsh
  setopt local_options warn_create_global
  autoload -Uz is-at-least 2>/dev/null || true
  if ! is-at-least 5.8; then
    awk '
      /^typeset -A / {
        if (match($0, /^typeset -A ([^=]+)=\((.*)\)$/, m)) {
          name = m[1]
          body = m[2]
          gsub(/^[[:space:]]+|[[:space:]]+$/, "", body)
          n = split(body, a, /[[:space:]]+/)
          out = "typeset -A " name "=("
          for (i=1; i<=n; i+=2) {
            if (a[i] == "") continue
            out = out " [" a[i] "]=" a[i+1]
          }
          out = out " )"
          print out
          next
        }
      }
      { print }
    '
  else
    cat
  fi
}

function print_aarr() {
  emulate -L zsh
  setopt local_options warn_create_global
  local MATCH MBEGIN MEND; local -a match mbegin mend  # appease 'warn_create_global'

  local input key val array_name
  local -A assoc_array

  # Read from standard input
  while IFS= read -r input; do
    if [[ $input =~ '^typeset -A ([a-zA-Z_][a-zA-Z0-9_]*)=\((.*)\)$' ]]; then
      array_name=${match[1]}
      printf '%-12s: %s\n' "\$assoc_arr" "${array_name}"
      eval "assoc_array=( ${match[2]} )"

      for key in ${(ok)assoc_array}; do
        val="$( print -r -- ${assoc_array[$key]} | subenv ANTIDOTE_HOME )"
        if [[ -z "$val" ]]; then
          printf '%-12s:\n' $key
        else
          printf '%-12s: %s\n' $key $val
        fi
      done
    else
      echo "Error: Input does not match an associative array declaration" >&2
      return 1
    fi
  done
}

function subenv {
  emulate -L zsh
  setopt local_options warn_create_global

  if (( $# == 0 )); then
    set -- HOME
  fi

  local -a sedargs=(-e "s|\$HOME|$HOME|g")
  while (( $# )); do
    if [[ -v "$1" ]]; then
      sedargs+=(-e "s|${(P)1}|\$$1|g")
    fi
    shift
  done
  sed "$sedargs[@]"
}

function aarr_val() {
  emulate -L zsh
  setopt local_options warn_create_global
  local MATCH MBEGIN MEND; local -a match mbegin mend  # appease 'warn_create_global'

  local input key val array_name
  local -A assoc_array

  # Read from standard input
  while IFS= read -r input; do
    if [[ $input =~ '^typeset -A ([a-zA-Z_][a-zA-Z0-9_]*)=\((.*)\)$' ]]; then
      array_name=${match[1]}
      eval "assoc_array=( ${match[2]} )"
      print -- "$assoc_array[$1]"
    else
      echo "Error: Input does not match an associative array declaration" >&2
      return 1
    fi
  done
}
