# antidote list tests

## Setup

```zsh
% source ./tests/__init__.zsh
% t_setup
%
```

Clone the standard test bundles:

```zsh
% antidote bundle <$ZDOTDIR/.base_test_fixtures.txt &>/dev/null
%
```

## List Command

### Directories

`antidote list`

```zsh
% antidote list | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/fakegitsite.com/bar/baz
$ANTIDOTE_HOME/fakegitsite.com/foo/bar
$ANTIDOTE_HOME/fakegitsite.com/foo/baz
$ANTIDOTE_HOME/fakegitsite.com/foo/qux
$ANTIDOTE_HOME/fakegitsite.com/getantidote/zsh-defer
$ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy
%
```

### Short

`antidote list --short-name`

```zsh
% antidote list --short-name | awk -F'\t' '{print $2}' | sort
bar/baz
foo/bar
foo/baz
getantidote/zsh-defer
git@fakegitsite.com:foo/qux
ohmy/ohmy
%
```

### URLs

`antidote list --url`

```zsh
% antidote list --url | awk -F'\t' '{print $2}' | sort
git@fakegitsite.com:foo/qux
https://fakegitsite.com/bar/baz
https://fakegitsite.com/foo/bar
https://fakegitsite.com/foo/baz
https://fakegitsite.com/getantidote/zsh-defer
https://fakegitsite.com/ohmy/ohmy
%
```

### SHA

`antidote list --short-name --short-sha`

```zsh
% antidote list --short-name --short-sha | sed 's/\t/    /g' | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/fakegitsite.com/bar/baz    bar/baz    1aa9550
$ANTIDOTE_HOME/fakegitsite.com/foo/bar    foo/bar    400b29a
$ANTIDOTE_HOME/fakegitsite.com/foo/baz    foo/baz    98cdde2
$ANTIDOTE_HOME/fakegitsite.com/foo/qux    git@fakegitsite.com:foo/qux    89661d7
$ANTIDOTE_HOME/fakegitsite.com/getantidote/zsh-defer    getantidote/zsh-defer    57ddc6f
$ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy    ohmy/ohmy    1cc5b7e
%
```

`antidote list --sha`

```zsh
% antidote list --short-name --sha | sed 's/\t/    /g' | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/fakegitsite.com/bar/baz    bar/baz    1aa9550512f5606c5c23b11f5a9ad660d6c10fb4
$ANTIDOTE_HOME/fakegitsite.com/foo/bar    foo/bar    400b29a76d68fd7c40bc7c0460424ab089b1e68a
$ANTIDOTE_HOME/fakegitsite.com/foo/baz    foo/baz    98cdde20c338bdb4df6efefd7f812d38ecc62b70
$ANTIDOTE_HOME/fakegitsite.com/foo/qux    git@fakegitsite.com:foo/qux    89661d7f95e6d805d4da6e1dc9bbaba9b126322a
$ANTIDOTE_HOME/fakegitsite.com/getantidote/zsh-defer    getantidote/zsh-defer    57ddc6fc6fba9862b899c483b6746b43c07dfb0d
$ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy    ohmy/ohmy    1cc5b7ebe76328350234e841e72729f40057e2b6
%
```

### JSONL

`antidote list --jsonl`

```zsh
% antidote list --jsonl | subenv ANTIDOTE_HOME
{"url":"https://fakegitsite.com/bar/baz","short_name":"bar/baz","type":"repo","path":"$ANTIDOTE_HOME/fakegitsite.com/bar/baz","sha":"1aa9550512f5606c5c23b11f5a9ad660d6c10fb4"}
{"url":"https://fakegitsite.com/foo/bar","short_name":"foo/bar","type":"repo","path":"$ANTIDOTE_HOME/fakegitsite.com/foo/bar","sha":"400b29a76d68fd7c40bc7c0460424ab089b1e68a"}
{"url":"https://fakegitsite.com/foo/baz","short_name":"foo/baz","type":"repo","path":"$ANTIDOTE_HOME/fakegitsite.com/foo/baz","sha":"98cdde20c338bdb4df6efefd7f812d38ecc62b70"}
{"url":"git@fakegitsite.com:foo/qux","short_name":"git@fakegitsite.com:foo/qux","type":"repo","path":"$ANTIDOTE_HOME/fakegitsite.com/foo/qux","sha":"89661d7f95e6d805d4da6e1dc9bbaba9b126322a"}
{"url":"https://fakegitsite.com/getantidote/zsh-defer","short_name":"getantidote/zsh-defer","type":"repo","path":"$ANTIDOTE_HOME/fakegitsite.com/getantidote/zsh-defer","sha":"57ddc6fc6fba9862b899c483b6746b43c07dfb0d"}
{"url":"https://fakegitsite.com/ohmy/ohmy","short_name":"ohmy/ohmy","type":"repo","path":"$ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy","sha":"1cc5b7ebe76328350234e841e72729f40057e2b6"}
%
```

## Teardown

```zsh
% t_teardown
%
```
