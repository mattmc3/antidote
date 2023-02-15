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
