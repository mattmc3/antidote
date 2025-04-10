# antidote bundle parser tests

## Setup

```zsh
% source ./tests/_setup.zsh
% source $T_PRJDIR/antidote.zsh
% zstyle ':antidote:gitremote' url 'https://fakegitsite.com/'
%
```

## Test bundle parser associative arrays

The bundle parser takes the antidote bundle format and returns an associative array
from the results of `declare -p parsed_bundle`

Test empty:

```zsh
% __antidote_parse_bundle
% __antidote_parse_bundle '# This is a full line comment'
%
```

Test basic foo/bar:

```zsh
% __antidote_parse_bundle 'foo/bar' | print_aarr
_dir      : $ANTIDOTE_HOME/foo/bar
_name     : foo/bar
_type     : repo
_url      : https://fakegitsite.com/foo/bar
ref       : foo/bar
%
```

Test trailing comments work:

```zsh
% __antidote_parse_bundle 'foo/bar  # trailing comment' | print_aarr
_dir      : $ANTIDOTE_HOME/foo/bar
_name     : foo/bar
_type     : repo
_url      : https://fakegitsite.com/foo/bar
ref       : foo/bar
%
```

Test annotations:

```zsh
% __antidote_parse_bundle 'https://fakegitsite.com/foo/bar path:plugins/baz kind:fpath pre:"echo hello world" branch:bark' | print_aarr
_dir      : $ANTIDOTE_HOME/foo/bar
_name     : foo/bar
_type     : url
_url      : https://fakegitsite.com/foo/bar
branch    : bark
kind      : fpath
path      : plugins/baz
pre       : echo hello world
ref       : https://fakegitsite.com/foo/bar
%
```

Test word:

```zsh
% __antidote_parse_bundle 'foo' | print_aarr
_dir      : foo
_name     : foo
_type     : word
_url      : https://fakegitsite.com/foo
ref       : foo
%
```

Test unknown bundle type:

```zsh
% __antidote_parse_bundle 'foo:bar:baz' | print_aarr
_dir      : foo:bar:baz
_name     : foo:bar:baz
_type     : ?
_url      : https://fakegitsite.com/foo:bar:baz
ref       : foo:bar:baz
%
```

```zsh
% __antidote_parse_bundle 'user/repo foo:bar:baz' | print_aarr
_dir      : $ANTIDOTE_HOME/user/repo
_name     : user/repo
_type     : repo
_url      : https://fakegitsite.com/user/repo
foo       : bar:baz
ref       : user/repo
%
```

Test path bundle types

```zsh
% eval $(__antidote_parse_bundle '$T_PRJDIR/antidote.zsh'); echo $parsed_bundle[_type]
file
% eval $(__antidote_parse_bundle '$T_PRJDIR/functions'); echo $parsed_bundle[_type]
dir
% eval $(__antidote_parse_bundle $T_PRJDIR/antidote.zsh); echo $parsed_bundle[_type]
file
% eval $(__antidote_parse_bundle $T_PRJDIR/functions); echo $parsed_bundle[_type]
dir
% eval $(__antidote_parse_bundle \$FAKE/DIR); echo $parsed_bundle[_type]
path
% eval $(__antidote_parse_bundle \$FAKE/DIR/); echo $parsed_bundle[_type]
path
% eval $(__antidote_parse_bundle '/foo/bar'); echo $parsed_bundle[_type]
path
% eval $(__antidote_parse_bundle 'foobar/'); echo $parsed_bundle[_type]
relpath
% eval $(__antidote_parse_bundle '~/foo/bar'); echo $parsed_bundle[_type]
path
% eval $(__antidote_parse_bundle '$foo/bar'); echo $parsed_bundle[_type]
path
% eval $(__antidote_parse_bundle \$ZDOTDIR/foo); echo $parsed_bundle[_type]
path
% eval $(__antidote_parse_bundle \$ZDOTDIR/.zsh_plugins.txt); echo $parsed_bundle[_type]
file
% eval $(__antidote_parse_bundle '~/.zshenv'); echo $parsed_bundle[_type]
path
% touch ~/.zshenv
% eval $(__antidote_parse_bundle '~/.zshenv'); echo $parsed_bundle[_type]
file
% eval $(__antidote_parse_bundle 'foo/bar/baz'); echo $parsed_bundle[_type]
relpath
% eval $(__antidote_parse_bundle './foo'); echo $parsed_bundle[_type]
relpath
% eval $(__antidote_parse_bundle '../foo'); echo $parsed_bundle[_type]
relpath
%
```

Test repo bundle types

```zsh
% eval $(__antidote_parse_bundle 'git@github.com:foo/bar.git'); echo $parsed_bundle[_type]
sshurl
% eval $(__antidote_parse_bundle 'https://github.com/foo/bar'); echo $parsed_bundle[_type]
url
% eval $(__antidote_parse_bundle 'https://github.com/foo/bar.git'); echo $parsed_bundle[_type]
url
% eval $(__antidote_parse_bundle 'foo/bar'); echo $parsed_bundle[_type]
repo
% eval $(__antidote_parse_bundle 'bar/baz.git'); echo $parsed_bundle[_type]
repo
%
```

Test word bundle types

```zsh
% eval $(__antidote_parse_bundle foobar); echo $parsed_bundle[_type]
word
% eval $(__antidote_parse_bundle foo bar baz); echo $parsed_bundle[_type]
word
% eval $(__antidote_parse_bundle 'foo bar baz'); echo $parsed_bundle[_type]
word
%
```

Test bad/funky bundle types

```zsh
% eval $(__antidote_parse_bundle); echo $parsed_bundle[_type]  # empty

% eval $(__antidote_parse_bundle ''); echo $parsed_bundle[_type]

% eval $(__antidote_parse_bundle '    '); echo $parsed_bundle[_type]

% # https:/ instead of https://
% eval $(__antidote_parse_bundle 'https:/bad.com/foo/bar.git'); echo $parsed_bundle[_type]
?
%
```

## Teardown

```zsh
% t_teardown
%
```
