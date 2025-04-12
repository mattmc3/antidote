# antidote bundle parser tests

## Setup

```zsh
% source ./tests/__init__.zsh
% t_setup
% zstyle ':antidote:gitremote' url 'https://fakegitsite.com/'
%
```

## Test bundle parser associative arrays

The bundle parser takes the antidote bundle format and returns an associative array
from the results of `declare -p parsed_bundle`

Test empty:

```zsh
% __antidote_parser
% __antidote_parser '# This is a full line comment'
%
```

Test assoc array for repo

```zsh
% __antidote_parser 'foo/bar' | print_aarr
$assoc_arr  : bundle
_repo       : foo/bar
_repodir    : foo/bar
_type       : repo
_url        : https://fakegitsite.com/foo/bar
name        : foo/bar
%
```

Test assoc array for repo in compatibility mode

```zsh
% zstyle ':antidote:bundle' use-friendly-names off
% __antidote_parser 'foo/bar' | print_aarr
$assoc_arr  : bundle
_repo       : foo/bar
_repodir    : https-COLON--SLASH--SLASH-fakegitsite.com-SLASH-foo-SLASH-bar
_type       : repo
_url        : https://fakegitsite.com/foo/bar
name        : foo/bar
% zstyle ':antidote:bundle' use-friendly-names on
%
```

Test assoc array for path

```zsh
% __antidote_parser '$ZSH_CUSTOM/foo' 'mybundle' | print_aarr
$assoc_arr  : mybundle
_type       : path
name        : $ZSH_CUSTOM/foo
%
```

Test assoc array for jibberish

```zsh
% __antidote_parser 'a b c d:e:f' | print_aarr
$assoc_arr  : bundle
_type       : ?
b           :
c           :
d           : e:f
name        : a
% __antidote_parser 'foo bar:baz' | print_aarr
$assoc_arr  : bundle
_type       : ?
bar         : baz
name        : foo
%
```

Test assoc array for everything

```zsh
% __antidote_parser 'foo/bar branch:baz kind:zsh path:plugins/baz pre:precmd post:"post cmd"' | print_aarr
$assoc_arr  : bundle
_repo       : foo/bar
_repodir    : foo/bar
_type       : repo
_url        : https://fakegitsite.com/foo/bar
branch      : baz
kind        : zsh
name        : foo/bar
path        : plugins/baz
post        : post cmd
pre         : precmd
%
```

## Test specific keys have known values

Test name:

```zsh
% __antidote_parser 'foo/bar' | aarr_val name
foo/bar
%
```

Test \_type:

```zsh
% __antidote_parser 'foo/bar' | aarr_val _type
repo
% __antidote_parser 'https://github.com/foo/bar' | aarr_val _type
url
% __antidote_parser 'git@bitbucket.org:foo/bar' | aarr_val _type
url
% __antidote_parser '$foo/bar' | aarr_val _type
path
% __antidote_parser '$foo/bar/baz.zsh' | aarr_val _type
path
% __antidote_parser '~foo/bar' | aarr_val _type
path
% __antidote_parser '~/foo' | aarr_val _type
path
% __antidote_parser './foo.zsh' | aarr_val _type
path
% __antidote_parser '../foo.zsh' | aarr_val _type
path
% __antidote_parser 'foo/bar/' | aarr_val _type
path
% __antidote_parser 'foo:bar' | aarr_val _type
?
% __antidote_parser 'bad@gitsite.com/foo/bar' | aarr_val _type
?
% __antidote_parser 'http:/badsite.com/foo/bar' | aarr_val _type
?
% __antidote_parser 'https://badsite.com/foo/bar/baz' | aarr_val _type
?
% __antidote_parser 'https://badsite.com/foo' | aarr_val _type
?
%
```

## Teardown

```zsh
% t_teardown
%
```
