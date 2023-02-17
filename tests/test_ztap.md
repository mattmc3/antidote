# antidote ZTAP tests

## Setup

```zsh
% ZTAP_TEST_DIR=$PWD/tests/ztap
%
```

## Tests

```zsh
% $ZTAP_TEST_DIR/test_setopts_respected.zsh
ok 1 starting state noaliases val='on'
ok 2 starting state autocd val='off'
ok 3 'antidote load' succeeds
ok 4 'antidote load' changed noaliases to 'off'
ok 5 'antidote load' changed autocd to 'on'
ok 6 'antidote -v' succeeds with 'setopt posix_identifiers'
ok 7 'antidote -v' empty stderr with 'setopt posix_identifiers'
ok 8 'antidote -h' succeeds with 'setopt posix_identifiers'
ok 9 'antidote -h' empty stderr with 'setopt posix_identifiers'
ok 10 'antidote help' succeeds with 'setopt posix_identifiers'
ok 11 'antidote help' empty stderr with 'setopt posix_identifiers'
ok 12 few enabled options (2)
ok 13 'antidote load' succeeds
ok 14 zillions of enabled options (>150)

1..14
# pass 14
# ok
%
```

```zsh
% $ZTAP_TEST_DIR/test_parsebundles.zsh
ok 1 parsing bundle foo/bar => name\tfoo/bar
ok 2 parse bad bundle fails
ok 3 parse bad bundle prints error
ok 4 parse bundle: 'foo/bar'
ok 5 parse bundle: 'https://github.com/foo/bar path:lib branch:dev'
ok 6 parse bundle: 'git@github.com:foo/bar.git kind:clone branch:main'
ok 7 parse bundle: 'foo/bar kind:fpath abc:xyz'
ok 8 parse bundle: 'foo/bar\tkind:path\r\n'
ok 9 parse bundle: 'foo/bar path:plugins/myplugin kind:path  # trailing comment'
ok 10 parse bundle: '# comment'
ok 11 parsing quoted bundle string with newline sep
ok 12 parsing multiline bundle with comments
ok 13 parsing complex bundle with crlf

1..13
# pass 13
# ok
%
```
