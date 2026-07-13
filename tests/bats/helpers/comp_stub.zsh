# Load functions/_antidote with compsys stubbed so its helper functions
# can be unit tested in plain zsh (no zle, no compinit).
#
# usage: zsh -f tests/bats/helpers/comp_stub.zsh <helper-function> [args...]

emulate -L zsh
0=${(%):-%x}
cd ${0:A:h:h:h:h}

# Canned antidote CLI surface used by the completion helpers.
antidote() {
  case "$1" in
    --help)
      print -r -- 'usage: antidote [<flags>] <command> [<args> ...]

commands:
  bundle    Clone bundle(s) and generate the static load script
  install   Clone a new bundle and add it to your plugins file
  update    Update antidote and its cloned bundles
  help      Show documentation
  load      Statically source all bundles from the plugins file'
      ;;
    list)
      print -rl -- \
        'https://github.com/foo/bar' \
        'git@github.com:baz/qux' \
        'https://gitlab.com/group/repo'
      ;;
  esac
}

# compsys stubs: _describe prints the named candidate array, the rest
# are no-ops so sourcing the file (which ends with `_antidote "$@"`)
# is harmless.
_arguments() { return 1 }
_describe() {
  [[ "$1" == -t ]] && shift 2
  shift
  print -rl -- ${(P)1}
}
compadd() { : }
_files() { : }

source functions/_antidote 2>/dev/null

"$@"
