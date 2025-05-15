# antidote2 tests

## Setup

```zsh
% path+=($PWD)
% ANTIDOTE_DEBUG=true
% subenv() { : "${1:=HOME}"; sed "s|$(eval echo \"\$$1\")|$\\$1|g" ;}
%
```

## Helper funcs

### _abspath

`_abspath` returns absolute paths

```zsh
% antidote2 --debug run _abspath ./antidote2 | subenv PWD
$PWD/antidote2
%
```

### _bundletype

`_bundletype` identifies the type of bundle string passed

```zsh
% antidote2 --debug run _bundletype
empty
% antidote2 --debug run _bundletype foo
word
% antidote2 --debug run _bundletype https://gitsite.com/foo/bar
url
% antidote2 --debug run _bundletype git@gitsite.com:foo/bar.git
sshurl
% antidote2 --debug run _bundletype foo/bar/baz
relpath
% antidote2 --debug run _bundletype foo/
relpath
% antidote2 --debug run _bundletype /foo/bar
path
% antidote2 --debug run _bundletype foo/bar
repo
%
```

### _cachedir

`_cachedir` gets cache dir

```zsh
% ANTIDOTE_OSTYPE=darwin21.3.0 antidote2 --debug run _cachedir | subenv
$HOME/Library/Caches
% ANTIDOTE_OSTYPE=msys LOCALAPPDATA=$HOME/AppData antidote2 --debug run _cachedir | subenv
$HOME/AppData
% ANTIDOTE_OSTYPE=linux antidote2 --debug run _cachedir | subenv
$HOME/.cache
% ANTIDOTE_OSTYPE=foobar XDG_CACHE_HOME=$HOME/.xdg-cache antidote2 --debug run _cachedir | subenv
$HOME/.xdg-cache
%
```

### _collect_args

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

### _git

`_git` wraps git and supports mocking

```zsh
% export ANTIDOTE_GIT=$PWD/tests/tools/mockgit
% antidote2 --debug run _git --version
mockgit version 0.0.0
% antidote2 --debug run _git foo
antidote: unexpected git error on command 'git foo'.
antidote: error details:
mockgit: mocking not implemented for command: mockgit foo
%
```

### _iscmd

`_iscmd` identifies commands

```zsh
% antidote2 --debug run _iscmd foobar #=> --exit 1
% antidote2 --debug run _iscmd git    #=> --exit 0
%
```

### _isfunc

`_isfunc` identifies functions

```zsh
% antidote2 --debug run _isfunc foobar  #=> --exit 1
% antidote2 --debug run _isfunc _isfunc #=> --exit 0
%
```

### _isurl

`_isurl` identifies urls

```zsh
% antidote2 --debug run _isurl foo #=> --exit 1
% antidote2 --debug run _isurl git@gitsite.com/foo/bar.git #=> --exit 1
% antidote2 --debug run _isurl https:/gitsite.com/foo/bar  #=> --exit 1
% antidote2 --debug run _isurl https://gitsite.com/foo/bar #=> --exit 0
% antidote2 --debug run _isurl git@gitsite.com:foo/bar.git #=> --exit 0
%
```

### _repeat

`_repeat` repeats strings with an optional joiner

```zsh
% antidote2 --debug run _repeat 3 "foo"
foofoofoo
% antidote2 --debug run _repeat 5 "la" "-"
la-la-la-la-la
%
```

### _url2path

`_url2path` converts URLs to paths

```zsh
% export ANTIDOTE_HOME=~/.cache/antidote
% antidote2 --debug run _url2path https://gitsite.com/foo/bar | subenv
$HOME/.cache/antidote/foo/bar
% antidote2 --debug run _url2path git@gitsite.com:foo/bar.git | subenv
$HOME/.cache/antidote/foo/bar
% unset ANTIDOTE_HOME
%
```

`_url2path` supports compatibility mode

```zsh
% export ANTIDOTE_HOME=~/.cache/antidote
% export ANTIDOTE_COMPATIBILITY_MODE=antibody
% antidote2 --debug run _url2path https://gitsite.com/foo/bar | subenv
$HOME/.cache/antidote/https-COLON--SLASH--SLASH-gitsite.com-SLASH-foo-SLASH-bar
% antidote2 --debug run _url2path git@gitsite.com:foo/bar.git | subenv
$HOME/.cache/antidote/git-AT-gitsite.com-COLON-foo-SLASH-bar.git
% unset ANTIDOTE_HOME ANTIDOTE_COMPATIBILITY_MODE
%
```

### _url2repo

`_url2repo` converts URLs to user/repo form

```zsh
% antidote2 --debug run _url2repo https://gitsite.com/foo/bar | subenv
foo/bar
% antidote2 --debug run _url2repo git@gitsite.com:foo/bar.git | subenv
foo/bar
%
```

### _wordsplit

`_wordsplit` uses the shell's lexer to word split respecting quotes

```zsh
% words=( "${(@f)$(antidote2 --debug run _wordsplit "foo:bar bar:baz")}" )
% printf '%s\n' "${words[@]}"
foo:bar
bar:baz
% words=( "${(@f)$(antidote2 --debug run _wordsplit 'foo:bar bar:"foo bar baz"')}" )
% printf '%s\n' "${words[@]}"
foo:bar
bar:foo bar baz
%
```

## Teardown

```zsh
% # todo
%
```
