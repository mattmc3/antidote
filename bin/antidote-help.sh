#!/usr/bin/env dash

THIS_FILE="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"

##? Usage: antidote path <bundle>
##?
##? Prints the path of a currently cloned bundle.
##?
##? Flags:
##?   -h, --help   Show context-sensitive help.
##?
##? Args:
##?   <bundle>     The Bundle path to print.
antidote_path() {
  :
}

##? Usage: antidote purge <bundle>
##?
##? Purges a bundle from your computer.
##?
##? Flags:
##?   -h, --help   Show context-sensitive help.
##?
##? Args:
##?   <bundle>     The bundle to be purged.
antidote_purge() {
  :
}

##? Usage: antidote update [-b|--bundles] [-s|--self]
##?        antidote update <bundle>
##?
##? Updates cloned bundle(s) and antidote itself.
##?
##? Flags:
##?   -h, --help     Show context-sensitive help.
##?   -s, --self     Update antidote.
##?   -b, --bundles  Update bundles.
##?
##? Args:
##?   <bundle>     The bundle to be updated.
antidote_update() {
  :
}

##? antidote - the cure to slow zsh plugin management
##?
##? Usage: antidote [<flags>] <command> [<args> ...]
##?
##? Flags:
##?   -h, --help           Show context-sensitive help
##?   -v, --version        Show application version
##?
##? Commands:
##?   help      Show documentation
##?   load      Statically source all bundles from the plugins file
##?   bundle    Clone bundle(s) and generate the static load script
##?   install   Clone a new bundle and add it to your plugins file
##?   update    Update antidote and its cloned bundles
##?   purge     Remove a cloned bundle
##?   home      Print where antidote is cloning bundles
##?   list      List cloned bundles
##?   path      Print the path of a cloned bundle
##?   init      Initialize the shell for dynamic bundles
antidote_help() {
  local name fn awk_script
  name="${1:-help}"
  fn="antidote_${name}"

  # shellcheck disable=SC2016
  awk_script='
    /^##\?/ {
      line = $0
      sub(/^##\?[[:space:]]?/, "", line)
      buf = buf line "\n"
      next
    }
    $0 == fn "() {" {
      printf "%s", buf
      found = 1
      exit 0
    }
        { buf = "" }
    END { if (!found) exit 1 }
  '
  awk -v fn="$fn" "$awk_script" "$THIS_FILE" || {
    # fallback to main help, unless we're already there
    printf "antidote: no help found for '%s'.\n\n" "$1"
    if [ "$fn" != "antidote_help" ]; then
      antidote_help help
    fi
    return 1
  }
}

antidote_help "$@"
