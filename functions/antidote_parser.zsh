#!/usr/bin/env zsh

#
# Parse the antidote DSL into a Zsh associative array, or JSONL
#

setopt WARN_CREATE_GLOBAL WARN_NESTED_VAR

: "${ANTIDOTE_COMPATIBILITY_MODE:=false}"
: "${ANTIDOTE_GIT_SITE:=https://github.com}"

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
  printf '%s\n' "$str"
}

# Add more properties to the bundle dict
function enhance_bundle {
  local -A bundle=("$@")
  local scrubbed bundle_id

  bundle_id="$bundle[name]"
  scrubbed="${bundle_id%/}" # strip trailing slash
  scrubbed="${scrubbed%.git}" # strip trailing .git

  # Enhance the bundle with metadata fields. Metadata fields begin with an underscore
  # since those will never be part of the DSL. Let's start with _type, which tells us
  # whether the bundle is a URL, a user/repo, or a path
  if [[ "$bundle_id" == *://*/*/* || "$bundle_id" == (ssh|git)@*:*/* ]]; then
    if [[ "$bundle_id" == *://*/*/*/* || "$bundle_id" == *@*:*/*/* ]]; then
      bundle[__type__]="?"
    else
      bundle[__type__]="url"
    fi
  elif [[ "$bundle_id" == *('@'|':')* ]] ; then
    bundle[__type__]="?"  # bad URLs
  elif [[ "$bundle_id" == ('~'|'$'|'.')* ]]; then
    bundle[__type__]="path"
  elif [[ "$bundle_id" == */* && "$bundle_id" != */*/* ]]; then
    bundle[__type__]="repo"
  elif [[ "$bundle_id" == */* ]]; then
    bundle[__type__]="path"
  else
    bundle[__type__]="?"
  fi

  case "$bundle[__type__]" in
    url)
      bundle[__url__]="$bundle_id"
      scrubbed="${scrubbed#*:}"
      bundle[__repo__]="${scrubbed:h:t}/${scrubbed:t}"
      bundle[__path__]="\$ANTIDOTE_HOME/${bundle[__repo__]}"
      ;;
    repo)
      bundle[__url__]="${ANTIDOTE_GIT_SITE}/${bundle_id}"
      bundle[__repo__]="${bundle_id}"
      bundle[__path__]="\$ANTIDOTE_HOME/${bundle[__repo__]}"
      ;;
    path)
      bundle[__path__]="$bundle_id"
      ;;
  esac

  if is_true "$ANTIDOTE_COMPATIBILITY_MODE" && [[ -n "${bundle[__url__]}" && -n "${bundle[__path__]}" ]]; then
    bundle[__path__]="\$ANTIDOTE_HOME/$(sanitize_url "${bundle[__url__]}")"
  fi
  printf '%s\n' "${(@kv)bundle}"
}

function antidote_parser {
  local outfmt line lineno arg argno annotation value
  local key c
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

  # Normalize line endings
  bundle_dsl=${bundle_dsl//$'\r\n'/$'\n'}
  bundle_dsl=${bundle_dsl//$'\r'/$'\n'}

  while IFS= read -r line; do
    # (z): use shell wordsplitting rules
    # (Q): remove one level of quotes
    args=(${(Q)${(z)line}})
    argno=1
    bundle=()
    for arg in $args; do
      # as soon as we hit a comment marker at the start, we're done.
      [[ $arg == \#* ]] && break
      if (( argno == 1 )); then
        bundle[__line__]=$lineno
        bundle[name]=$arg
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

    # If -x enhance bundle, and if -j use JSONL for output
    if [[ $#bundle -gt 1 ]]; then
      if (( ${#o_enhance} )); then
        bundle=("${(@f)$(enhance_bundle "${(@kv)bundle}")}")
      fi
      [[ "$outfmt" != jsonl ]] && parsed_bundles+=("$(declare -p bundle)")
      if (( ${#o_jsonl} )); then
        printf '%s' "{"
        c=1
        for key in "${(@ok)bundle}"; do
          (( c > 1 )) && printf ','
          printf '"%s":"%s"' "$(json_escape "$key")" "$(json_escape "${bundle[$key]}")"
          (( c++ ))
        done
        printf '%s\n' "}"
      fi
    fi
    (( lineno++ ))
  done <<<"$bundle_dsl"

  if [[ ${#parsed_bundles} -gt 0 && "$outfmt" == (zsh|) ]]; then
    printf '%s\n' $parsed_bundles
  fi
}
antidote_parser "$@"
