#!/usr/bin/env zsh

#
# Parse the antidote DSL into a Zsh associative array, or JSONL
#

setopt WARN_CREATE_GLOBAL WARN_NESTED_VAR

: "${ANTIDOTE_COMPATIBILITY_MODE:=false}"

# Checks a string for truthiness (eg: "1", "y", "yes", "t", "true", "o", and "on")
function is_true {
  [[ -n "$1" && "${1:l}" == (1|y(es|)|t(rue|)|o(n|)) ]]
}

# Change URL string into a safe directory name
function sanitize_url {
  local str
  str="$1"
  str=${str:gs/\@/-AT-}
  str=${str:gs/\:/-COLON-}
  str=${str:gs/\//-SLASH-}
  printf '%s\n' "$str"
}

# Escape a string for JSONL output.
function json_escape {
  local str=$1
  str=${str//\\/\\\\}
  str=${str//\"/\\\"}
  str=${str//$'\n'/\\n}
  str=${str//$'\r'/\\r}
  str=${str//$'\t'/\\t}
  str=${str//$'\f'/\\f}
  str=${str//$'\b'/\\b}
  printf '%s\n' "$str"
}

# Add more properties to the bundle dict
function enhance_bundle {
  local -A bundle=("$@")
  local scrubbed last second_last

  scrubbed="${bundle[bundle]%/}" # strip trailing slash
  scrubbed="${scrubbed%.git}" # strip trailing .git

  # Set properties based on the type of bundle.
  case "${bundle[bundle]}" in
    \$*|~*|/*)
      bundle[__type__]=path
      bundle[__path__]="${bundle[bundle]}"
      ;;
    http://*|https://*|ssh@*|git@*)
      bundle[__type__]=repo
      bundle[__url__]="${bundle[bundle]}"
      scrubbed="${scrubbed#*:}"
      last="${scrubbed##*/}"
      second_last="${scrubbed%/*}"
      second_last="${second_last##*/}"
      bundle[__repo__]="${second_last}/${last}"
      ;;
    */*/*|*:*)
      bundle[__type__]="?"
      ;;
    */*)
      bundle[__type__]=repo
      bundle[__url__]="${ANTIDOTE_GIT_SITE:-https://github.com}/${bundle[bundle]}"
      bundle[__repo__]="${bundle[bundle]}"
      ;;
    *)
      bundle[__type__]="custom"
      ;;
  esac

  if [[ "${bundle[__type__]}" == repo ]]; then
    bundle[__path__]="\$ANTIDOTE_HOME/${bundle[__repo__]}"
  fi

  if is_true "$ANTIDOTE_COMPATIBILITY_MODE" && [[ -n "${bundle[__url__]}" && -n "${bundle[__path__]}" ]]; then
    bundle[__path__]="\$ANTIDOTE_HOME/$(sanitize_url "${bundle[__url__]}")"
  fi
  printf '%s\n' "${(@kv)bundle}"
}

function antidote_parser {
  local outfmt enhance line lineno arg argno annotation value
  local key val c
  local -a bundle_dsl parsed_bundles args
  local -A bundle

  local o_jsonl o_enhance
  zparseopts -D -M -- \
    j=o_jsonl    -jsonl=j   \
    x=o_enhance  -enhance=x ||
    return 1

  # Set the output format
  (( ${#o_jsonl} )) && outfmt=jsonl || outfmt=zsh

  # Combine args and stdin
  bundle_dsl="$({
    [[ $# -eq 0 ]] || printf '%b\n' "$*"
    [[ -t 0 ]] || cat
  })"
  lineno=1

  while IFS= read -r line; do
    # (z): use shell wordsplitting rules
    # (Q): remove one level of quotes
    args=(${(Q)${(z)line}})
    argno=1
    bundle=()
    for arg in $args; do
      [[ $arg == \#* ]] && break
      if (( argno == 1 )); then
        bundle[__line__]=$lineno
        bundle[bundle]=$arg
      else
        if [[ $arg != *:* ]]; then
          print -ru2 "antidote: Unexpected bundle annotation on line $lineno: '$arg'."
          return 1
        fi
        annotation=${arg%%:*}
        value=${arg#*:}
        bundle[$annotation]=$value
      fi
      (( argno++ ))
    done
    if [[ $#bundle -gt 1 ]]; then
      if (( ${#o_enhance} )); then
        bundle=("${(@f)$(enhance_bundle "${(@kv)bundle}")}")
      fi
      parsed_bundles+=("$(declare -p bundle)")
      if (( ${#o_jsonl} )); then
        printf '%s' "{"
        c=1
        for key in "${(@ok)bundle}"; do
          val="${bundle[$key]}"
          (( c > 1 )) && printf ','
          printf '"%s":"%s"' "$(json_escape "$key")" "$(json_escape "$val")"
          (( c++ ))
        done
        printf '%s\n' "}"
      fi
    fi
    (( lineno++ ))
  done <<<"$bundle_dsl"

  if [[ "$outfmt" == zsh ]]; then
    printf '%s\n' $parsed_bundles
  fi
}
antidote_parser "$@"
