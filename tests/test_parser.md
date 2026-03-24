# antidote bundle_parser tests

## Setup

```zsh
% source ./tests/__init__.zsh
% t_setup
% function bundle_parser() { antidote __private__ bundle_parser "$@"; }
%
```

## Test bundle parser associative arrays

The bundle parser takes the antidote bundle format and returns a flat key-value
string that can be read into an associative array.

Test empty:

```zsh
% echo | bundle_parser
% echo '# This is a full line comment' | bundle_parser
%
```

Test assoc array for repo

```zsh
% echo 'foo/bar' | bundle_parser | print_aarr
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar
%
```

Test assoc array for repo in escaped path

```zsh
% zstyle ':antidote:bundle' path-style escaped
% echo 'foo/bar' | bundle_parser | print_aarr
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-fakegitsite.com-SLASH-foo-SLASH-bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar
% zstyle -d ':antidote:bundle' path-style
%
```

Test assoc array for path

```zsh
% echo '$ZSH_CUSTOM/foo' | bundle_parser | print_aarr
__bundle__  : $ZSH_CUSTOM/foo
__type__    : path
%
```

Test assoc array for jibberish

```zsh
% echo 'a b c d:e:f' | bundle_parser | print_aarr
__bundle__  : a
__error__   : error: Expecting 'key:value' form for annotation 'c'.
__type__    : word
d           : e:f
% echo 'foo bar:baz' | bundle_parser | print_aarr
__bundle__  : foo
__type__    : word
bar         : baz
%
```

Test assoc array for everything

```zsh
% echo 'foo/bar branch:baz kind:zsh path:plugins/baz pre:precmd post:"post cmd"' | bundle_parser | print_aarr
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar
branch      : baz
kind        : zsh
path        : plugins/baz
post        : post cmd
pre         : precmd
%
```

## Test specific keys have known values

Test __bundle__:

```zsh
% echo 'foo/bar' | bundle_parser | bundle_val __bundle__
foo/bar
%
```

Test __type__:

```zsh
% echo 'foo/bar' | bundle_parser | bundle_val __type__
repo
% echo 'https://github.com/foo/bar' | bundle_parser | bundle_val __type__
url
% echo 'git@bitbucket.org:foo/bar' | bundle_parser | bundle_val __type__
ssh_url
% echo '$foo/bar' | bundle_parser | bundle_val __type__
path
% echo '$foo/bar/baz.zsh' | bundle_parser | bundle_val __type__
path
% echo '~foo/bar' | bundle_parser | bundle_val __type__
path
% echo '~/foo' | bundle_parser | bundle_val __type__
path
% echo './foo.zsh' | bundle_parser | bundle_val __type__
path
% echo '../foo.zsh' | bundle_parser | bundle_val __type__
path
% echo 'foo/bar/' | bundle_parser | bundle_val __type__
relpath
% echo 'foo:bar' | bundle_parser | bundle_val __type__
?
% echo 'bad@gitsite.com/foo/bar' | bundle_parser | bundle_val __type__
?
% echo 'http:/badsite.com/foo/bar' | bundle_parser | bundle_val __type__
?
% echo 'https://gitlab.com/group/subgroup/repo' | bundle_parser | bundle_val __type__
url
% echo 'https://gist.github.com/abc123def456' | bundle_parser | bundle_val __type__
url
%
```

Test __url__:

```zsh
% echo 'foo/bar' | bundle_parser | bundle_val __url__
https://fakegitsite.com/foo/bar
% echo 'https://github.com/foo/bar' | bundle_parser | bundle_val __url__
https://github.com/foo/bar
% echo 'git@bitbucket.org:foo/bar' | bundle_parser | bundle_val __url__
git@bitbucket.org:foo/bar
% echo '$foo/bar' | bundle_parser | bundle_val __url__

% echo 'bad@gitsite.com/foo/bar' | bundle_parser | bundle_val __url__

% echo 'http:/badsite.com/foo/bar' | bundle_parser | bundle_val __type__
?
% echo 'https://gitlab.com/group/subgroup/repo' | bundle_parser | bundle_val __url__
https://gitlab.com/group/subgroup/repo
% echo 'https://gist.github.com/abc123def456' | bundle_parser | bundle_val __url__
https://gist.github.com/abc123def456
%
```

## Test __bundle__ for various bundle types

```zsh
% echo 'foo/bar' | bundle_parser | bundle_val __bundle__
foo/bar
% echo 'https://github.com/foo/bar' | bundle_parser | bundle_val __bundle__
https://github.com/foo/bar
% echo 'git@bitbucket.org:foo/bar' | bundle_parser | bundle_val __bundle__
git@bitbucket.org:foo/bar
% echo '$foo/bar' | bundle_parser | bundle_val __bundle__
$foo/bar
% echo '$foo/bar/baz.zsh' | bundle_parser | bundle_val __bundle__
$foo/bar/baz.zsh
% echo '~foo/bar' | bundle_parser | bundle_val __bundle__
~foo/bar
% echo '~/foo' | bundle_parser | bundle_val __bundle__
~/foo
% echo './foo.zsh' | bundle_parser | bundle_val __bundle__
./foo.zsh
% echo '../foo.zsh' | bundle_parser | bundle_val __bundle__
../foo.zsh
% echo 'foo/bar/' | bundle_parser | bundle_val __bundle__
foo/bar/
% echo 'foo:bar' | bundle_parser | bundle_val __bundle__
foo:bar
% echo 'bad@gitsite.com/foo/bar' | bundle_parser | bundle_val __bundle__
bad@gitsite.com/foo/bar
% echo 'http:/typo.com/foo/bar' | bundle_parser | bundle_val __bundle__
http:/typo.com/foo/bar
% echo 'https://gitlab.com/group/subgroup/repo' | bundle_parser | bundle_val __bundle__
https://gitlab.com/group/subgroup/repo
% echo 'https://gist.github.com/abc123def456' | bundle_parser | bundle_val __bundle__
https://gist.github.com/abc123def456
%
```

## Test pin annotation

```zsh
% echo 'foo/bar pin:abc123' | bundle_parser | print_aarr
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar
pin         : abc123
%
```

Pin with kind:clone:

```zsh
% echo 'foo/bar kind:clone pin:64642c5691051ba0d82f5bda60b745f6fd042325' | bundle_parser | print_aarr
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar
kind        : clone
pin         : 64642c5691051ba0d82f5bda60b745f6fd042325
%
```

## Test SSH URL parsing

SSH URL type with .git suffix:

```zsh
% echo 'git@bitbucket.org:foo/bar.git' | bundle_parser | bundle_val __type__
ssh_url
% echo 'git@bitbucket.org:foo/bar.git' | bundle_parser | bundle_val __bundle__
git@bitbucket.org:foo/bar.git
%
```

SSH URL __short__ preserves the full URL:

```zsh
% echo 'git@bitbucket.org:foo/bar' | bundle_parser | bundle_val __short__
git@bitbucket.org:foo/bar
% echo 'git@bitbucket.org:foo/bar.git' | bundle_parser | bundle_val __short__
git@bitbucket.org:foo/bar
%
```

SSH URL __dir__:

```zsh
% echo 'git@fakegitsite.com:foo/qux' | bundle_parser | print_aarr
__bundle__  : git@fakegitsite.com:foo/qux
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/qux
__short__   : git@fakegitsite.com:foo/qux
__type__    : ssh_url
__url__     : git@fakegitsite.com:foo/qux
%
```

## Test other annotations

Conditional:

```zsh
% echo 'foo/bar conditional:is-macos' | bundle_parser | bundle_val conditional
is-macos
%
```

Autoload:

```zsh
% echo 'foo/bar autoload:functions' | bundle_parser | bundle_val autoload
functions
%
```

fpath-rule:

```zsh
% echo 'foo/bar fpath-rule:prepend' | bundle_parser | bundle_val fpath-rule
prepend
%
```

## Test multiline input

Multiple bundles parsed at once:

```zsh
% printf 'foo/bar\nbar/baz kind:clone\n' | bundle_parser | bundle_val __bundle__
foo/bar
bar/baz
% printf 'foo/bar\nbar/baz kind:clone\n' | bundle_parser | bundle_val kind

clone
%
```

Comments and blanks produce no output but don't break line counting:

```zsh
% printf '# comment\n\nfoo/bar\n' | bundle_parser | bundle_val __lineno__
3
%
```

## Teardown

```zsh
% t_teardown
%
```
