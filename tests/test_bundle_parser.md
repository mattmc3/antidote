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
% __antidote_parse_bundle | normalize_assoc_arr
% __antidote_parse_bundle '# This is a full line comment' | normalize_assoc_arr
% __antidote_parse_bundle 'foo/bar' | normalize_assoc_arr
typeset -A parsed_bundle=( [name]=foo/bar )
% __antidote_parse_bundle 'foo/bar  # trailing comment' | normalize_assoc_arr
typeset -A parsed_bundle=( [name]=foo/bar )
% __antidote_parse_bundle 'https://fakegitsite.com/foo/bar path:plugins/baz kind:fpath pre:"echo hello world"' | normalize_assoc_arr
typeset -A parsed_bundle=( [kind]=fpath [name]=https://fakegitsite.com/foo/bar [path]=plugins/baz [pre]='echo hello world' )
%
```

Test funky weirdness

```zsh
% __antidote_parse_bundle 'foo' | normalize_assoc_arr
typeset -A parsed_bundle=( [name]=foo )
% __antidote_parse_bundle 'foo:bar:baz' | normalize_assoc_arr
typeset -A parsed_bundle=( [name]=foo:bar:baz )
% __antidote_parse_bundle 'user/repo foo:bar:baz' | normalize_assoc_arr
typeset -A parsed_bundle=( [foo]=bar:baz [name]=user/repo )
%
```

## Teardown

```zsh
% t_teardown
%
```
