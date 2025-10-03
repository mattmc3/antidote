# antidote v2 tests

## setup

```zsh
% source $PWD/tests/t_init.zsh
%
```

## antidote version

```zsh
% antidote2 --version
antidote version 2.0.0 (abcd123)
%
% # Ensure aliases all work
% test "$(antidote2 --version)" = "$(antidote2 -v)" #=> --exit 0
%
```

## antidote help

```zsh
% antidote2 --help
antidote - the cure to slow zsh plugin management

Usage: antidote [<flags>] <command> [<args> ...]

Flags:
  -h, --help             Show context-sensitive help.
  -v, --version          Show application version.

Commands:
  help <command>         Show documentation.
  bundle [<bundles>...]  Clone bundle(s) and generate Zsh source.
  update                 Update cloned bundles.
  home                   Print where antidote is cloning bundles.
  purge <bundle>         Remove a cloned bundle.
  list                   List cloned bundles.
  path <bundle>          Print the path of a cloned bundle.
  init                   Initialize the shell for dynamic bundles.
%
% # Ensure aliases all work
% test "$(antidote2 --help)" = "$(antidote2 -h)" #=> --exit 0
% test "$(antidote2 --help)" = "$(antidote2 help)" #=> --exit 0
%
```

## antidote home

`antidote home` command exists

```zsh
% antidote2 home &>/dev/null; echo $?
0
%
```

`antidote home --h/--help` works

```zsh
% antidote2 home --help
usage: antidote home

Prints where antidote is cloning bundles.

Flags:
  -h, --help   Show context-sensitive help.
% test "$(antidote2 home --help)" = "$(antidote2 home -h)" #=> --exit 0
% test "$(antidote2 home --help)" = "$(antidote2 help home)" #=> --exit 0
0
%
```

`$ANTIDOTE_HOME` is used if set...

```zsh
% export ANTIDOTE_HOME=$HOME/.cache/antidote
% antidote2 home | subenv
$HOME/.cache/antidote
% unset ANTIDOTE_HOME
%
```

`antidote home` is `~/Library/Caches/antidote` on macOS

```zsh
% export ANTIDOTE_OSTYPE=darwin21.3.0
% antidote2 home | subenv
$HOME/Library/Caches/antidote
% unset ANTIDOTE_OSTYPE
%
```

`antidote home` is `$LOCALAPPDATA/antidote` on msys

```zsh
% export ANTIDOTE_OSTYPE=msys
% export LOCALAPPDATA=$HOME/AppData
% antidote2 home | subenv
$HOME/AppData/antidote
% unset ANTIDOTE_OSTYPE LOCALAPPDATA
%
```

`antidote home` uses `$XDG_CACHE_HOME` on an OS that defines it.

```zsh
% # Setup
% export ANTIDOTE_OSTYPE=foobar
% OLD_XDG_CACHE_HOME=$XDG_CACHE_HOME; XDG_CACHE_HOME=$HOME/.xdg-cache
% # Run test
% antidote2 home | subenv XDG_CACHE_HOME
$XDG_CACHE_HOME/antidote
% # Teardown
% unset ANTIDOTE_OSTYPE; XDG_CACHE_HOME=$OLD_XDG_CACHE_HOME
%
```

`antidote home` uses `$HOME/.cache` otherwise.

```zsh
% # Setup
% export ANTIDOTE_OSTYPE=foobar
% OLD_XDG_CACHE_HOME=$XDG_CACHE_HOME; XDG_CACHE_HOME=
% # Run test
% antidote2 home | subenv
$HOME/.cache/antidote
% # Teardown
% unset ANTIDOTE_OSTYPE; XDG_CACHE_HOME=$OLD_XDG_CACHE_HOME
%
```

## antidote init

```zsh
% antidote2 init | subenv
#!/usr/bin/env zsh
antidote() {
  local antidote_cmd="$PWD/antidote2"
  case "$1" in
    bundle)
      source <( $antidote_cmd $@ ) || $antidote_cmd $@
      ;;
    *)
      $antidote_cmd $@
      ;;
  esac
}

_antidote() {
  IFS=' ' read -A reply <<< "help bundle update home purge list init"
}
compctl -K _antidote antidote
%
```

## antidote path

```zsh
% export ANTIDOTE_HOME=$HOME/.cache/repos
% antidote2 path ohmyzsh/ohmyzsh | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/ohmyzsh/ohmyzsh
% antidote2 path foo/bar
antidote2: path error: 'foo/bar' does not exist in cloned paths.
% unset ANTIDOTE_HOME
%
```

## antidote list

```zsh
% export ANTIDOTE_HOME=$HOME/.cache/repos
% antidote2 list | subenv ANTIDOTE_HOME
dracula/zsh                               $ANTIDOTE_HOME/dracula/zsh
mattmc3/antidote                          $ANTIDOTE_HOME/mattmc3/antidote
mattmc3/ez-compinit                       $ANTIDOTE_HOME/mattmc3/ez-compinit
mattmc3/zman                              $ANTIDOTE_HOME/mattmc3/zman
mattmc3/zsh_custom                        $ANTIDOTE_HOME/mattmc3/zsh_custom
ohmyzsh/ohmyzsh                           $ANTIDOTE_HOME/ohmyzsh/ohmyzsh
peterhurford/up.zsh                       $ANTIDOTE_HOME/peterhurford/up.zsh
romkatv/powerlevel10k                     $ANTIDOTE_HOME/romkatv/powerlevel10k
romkatv/zsh-bench                         $ANTIDOTE_HOME/romkatv/zsh-bench
romkatv/zsh-defer                         $ANTIDOTE_HOME/romkatv/zsh-defer
rummik/zsh-tailf                          $ANTIDOTE_HOME/rummik/zsh-tailf
rupa/z                                    $ANTIDOTE_HOME/rupa/z
sindresorhus/pure                         $ANTIDOTE_HOME/sindresorhus/pure
zdharma-continuum/fast-syntax-highlighting  $ANTIDOTE_HOME/zdharma-continuum/fast-syntax-highlighting
zsh-users/antigen                         $ANTIDOTE_HOME/zsh-users/antigen
zsh-users/zsh-autosuggestions             $ANTIDOTE_HOME/zsh-users/zsh-autosuggestions
zsh-users/zsh-completions                 $ANTIDOTE_HOME/zsh-users/zsh-completions
zsh-users/zsh-history-substring-search    $ANTIDOTE_HOME/zsh-users/zsh-history-substring-search
zsh-users/zsh-syntax-highlighting         $ANTIDOTE_HOME/zsh-users/zsh-syntax-highlighting
% antidote2 list -b | head -n 1 | tr -d '\t'
main
% antidote2 list -s | head -n 1 | tr -d '\t'
abcd1230abcd1230abcd1230abcd1230abcd1230
%
```

## private functions

Test cache_dir

```zsh
% export ANTIDOTE_OSTYPE=foobar
% OLD_XDG_CACHE_HOME=$XDG_CACHE_HOME; export XDG_CACHE_HOME=$HOME/.xdg-cache
% antidote2 --debug run cache_dir | subenv
$HOME/.xdg-cache
% unset ANTIDOTE_OSTYPE; XDG_CACHE_HOME=$OLD_XDG_CACHE_HOME
%
```

antidote parse_bundles

```zsh
% antidote2 --debug run parse_bundles 'ohmyzsh/ohmyzsh' | subenv ANTIDOTE_HOME
typeset -A abundle=( [_]=ohmyzsh/ohmyzsh [_line]=1 [_path]=$ANTIDOTE_HOME/ohmyzsh/ohmyzsh [_type]=short [_url]=https://github.com/ohmyzsh/ohmyzsh [kind]=zsh )
% antidote2 --debug run parse_bundles 'git@github.com:zsh-users/zsh-completions kind:fpath' | subenv ANTIDOTE_HOME
typeset -A abundle=( [_]=git@github.com:zsh-users/zsh-completions [_line]=1 [_path]=$ANTIDOTE_HOME/zsh-users/zsh-completions [_type]=url [_url]=git@github.com:zsh-users/zsh-completions [kind]=fpath )
%
```
