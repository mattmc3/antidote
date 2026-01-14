#!/bin/zsh
normalize_aarr() {
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
