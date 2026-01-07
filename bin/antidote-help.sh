#!/usr/bin/env dash

THIS_FILE="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"

antidote_foo() {
  :
}

antidote_path() {
  #? Usage: antidote path <bundle>
  #?
  #? Prints the path of a currently cloned bundle.
  #?
  #? Flags:
  #?   -h, --help   Show context-sensitive help.
  #?
  #? Args:
  #?   <bundle>     The Bundle path to print.
  :
}

antidote_purge() {
  #? Usage: antidote purge <bundle>
  #?
  #? Purges a bundle from your computer.
  #?
  #? Flags:
  #?   -h, --help   Show context-sensitive help.
  #?
  #? Args:
  #?   <bundle>     The bundle to be purged.
  :
}

antidote_update() {
  #? Usage: antidote update [-b|--bundles] [-s|--self]
  #?        antidote update <bundle>
  #?
  #? Updates cloned bundle(s) and antidote itself.
  #?
  #? Flags:
  #?   -h, --help     Show context-sensitive help.
  #?   -s, --self     Update antidote.
  #?   -b, --bundles  Update bundles.
  #?
  #? Args:
  #?   <bundle>     The bundle to be updated.
  :
}

antidote_help() {
  #? antidote - the cure to slow zsh plugin management
  #?
  #? Usage: antidote [<flags>] <command> [<args> ...]
  #?
  #? Flags:
  #?   -h, --help           Show context-sensitive help
  #?   -v, --version        Show application version
  #?
  #? Commands:
  #?   help      Show documentation
  #?   load      Statically source all bundles from the plugins file
  #?   bundle    Clone bundle(s) and generate the static load script
  #?   install   Clone a new bundle and add it to your plugins file
  #?   update    Update antidote and its cloned bundles
  #?   purge     Remove a cloned bundle
  #?   home      Print where antidote is cloning bundles
  #?   list      List cloned bundles
  #?   path      Print the path of a cloned bundle
  #?   init      Initialize the shell for dynamic bundles
  local name fn awk_script
  name="${1:-help}"
  fn="antidote_${name}"

  # shellcheck disable=SC2016
  awk_script='
    $0 == fn "() {" { found=1; show=1; next }
    show && /^[[:space:]]*#\?/ {
      sub(/^[[:space:]]*#\?[[:space:]]?/, "")
      print
      next
    }
    show { exit 0 }
    END { exit(found ? 0 : 1) }
  '
  awk -v fn="$fn" "$awk_script" "$THIS_FILE" || {
    # fallback to main help, unless we're already there
    printf "antidote: no help found for '%s'.\n\n" "$1" >&2
    [ "$fn" != "antidote_help" ] && antidote_help help
    return 1
  }
}

antidote_help "$@"
