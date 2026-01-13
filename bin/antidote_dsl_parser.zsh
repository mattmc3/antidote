#!/usr/bin/env zsh

# ./bin/antidote_dsl_parser.zsh <./tests/testdata/.zsh_plugins.txt

TAB="$(printf '\t')"

parse_antidote() {
  local line lineno arg argno
  local -a args

  lineno=1
  while IFS= read -r line; do
    # (z): use shell wordsplitting rules
    # (Q): remove one level of quotes
    args=(${(Q)${(z)line}})
    argno=1
    for arg in $args; do
      [[ $arg == \#* ]] && break
      if (( argno == 1 )); then
        printf '__lineno__:%s%s__bundle__:%s' "$lineno" "$TAB" "$arg"
      else
        printf '%s%s' "$TAB" "$arg"
      fi
      (( argno++ ))
    done
    [[ $argno -gt 1 ]] && printf '\n'
    (( lineno++ ))
  done
}
parse_antidote "$@"
