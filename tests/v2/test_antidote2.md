# antidote2 tests

## Setup

```zsh
% path+=($PWD)
% ANTIDOTE_DEBUG=true
% scrub_ver() { sed -E 's/^(.*[0-9]+\.[0-9]+\.[0-9]+).*/\1/' ;}
% subenv() { : "${1:=HOME}"; sed "s|$(eval echo \"\$$1\")|$\\$1|g" ;}
%
```

## Shellcheck

```zsh
% shellcheck --shell bash ./functions/antidote2.zsh #=> --exit 0
% shellcheck --shell bash ./functions/antidote2.zsh
%
```

## Help flag

Show antidote's help:

```zsh
% antidote2 --help
antidote - the cure to slow zsh plugin management

usage: antidote [<flags>] <command> [<args> ...]

Flags:
  -h, --help           Show context-sensitive help
  -v, --version        Show application version

Commands:
  help [<command>]
    Show documentation

  bundle <bundles>...
    Clone bundle(s) and generate the static load script

  update
    Update antidote and its cloned bundles

  home
    Print where antidote is cloning bundles

  purge <bundle>
    Remove a cloned bundle

  list
    List cloned bundles

  path <bundle>
    Print the path of a cloned bundle

  init
    Initialize the shell for dynamic bundles
%
```

antidote help alternatives all produce the same output:

```zsh
% dash_h="$(antidote2 -h)"
% doubledash_help="$(antidote2 --help)"
% help="$(antidote2 help)"
% [[ "$dash_h" == "$doubledash_help" ]] #=> --exit 0
% [[ "$dash_h" == "$help" ]] #=> --exit 0
%
```

## Version flag

Show antidote's version:

```zsh
% antidote2 --version | scrub_ver
antidote version 2.0.0
%
```

antidote version alternatives all produce the same output:

```zsh
% dash_v="$(antidote2 -v)"
% doubledash_version="$(antidote2 --version)"
% [[ "$dash_v" == "$doubledash_version" ]] #=> --exit 0
%
```

## Private funcs

`_abspath` returns absolute paths

```zsh
% antidote2 --debug run _abspath ./antidote2 | subenv PWD
$PWD/antidote2
%
```

`_isfunc` identifies functions

```zsh
% antidote2 --debug run _isfunc foobar ./antidote2 #=> --exit 1
% antidote2 --debug run _isfunc _isfunc ./antidote2 #=> --exit 0
%
```

`_iscmd` identifies commands

```zsh
% antidote2 --debug run _iscmd foobar ./antidote2 #=> --exit 1
% antidote2 --debug run _iscmd git ./antidote2 #=> --exit 0
%
```

`_collect_args` collects args
```zsh
% zero=( ${(@f)$(antidote2 --debug run _collect_args)} )
% echo "${#zero}"
0
% one=( ${(@f)$(antidote2 --debug run _collect_args a)} )
% echo "${#one}"
1
% three_three=( ${(@f)$(printf '%s\n' d e f | antidote2 --debug run _collect_args a b c)} )
% echo $#three_three
6
% printf '%s\n' "${three_three[@]}"
a
b
c
d
e
f
%
```

`_cachedir`

## Teardown

```zsh
% # todo
%
```
