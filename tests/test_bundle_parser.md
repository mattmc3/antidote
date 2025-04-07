# antidote bundle parser tests

## Setup

```zsh
% source ./tests/_setup.zsh
% source ./antidote.zsh
%
```

## Test bundle parser associative arrays

The bundle parser takes the antidote bundle format and returns an associative array
from the results of `declare -p parsed_bundle`

```zsh
% __antidote_parse_bundle
% __antidote_parse_bundle '# This is a full line comment'
% __antidote_parse_bundle 'foo/bar'
typeset -A parsed_bundle=( [repo]=foo/bar )
% __antidote_parse_bundle 'foo/bar  # trailing comment'
typeset -A parsed_bundle=( [repo]=foo/bar )
% __antidote_parse_bundle 'https://gitsite.com/foo/bar path:plugins/baz kind:fpath pre:"echo hello world"'
typeset -A parsed_bundle=( [kind]=fpath [path]=plugins/baz [pre]='echo hello world' [repo]=https://gitsite.com/foo/bar )
%
```

Test funky weirdness

```zsh
% __antidote_parse_bundle 'foo'
typeset -A parsed_bundle=( [repo]=foo )
% __antidote_parse_bundle 'foo:bar:baz'
typeset -A parsed_bundle=( [repo]=foo:bar:baz )
% __antidote_parse_bundle 'user/repo foo:bar:baz'
typeset -A parsed_bundle=( [foo]=bar:baz [repo]=user/repo )
%
```

## Teardown

```zsh
% t_teardown
%
```
