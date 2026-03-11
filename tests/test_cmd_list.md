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

### Short

`antidote list --short`

```zsh
% antidote list --short | subenv ANTIDOTE_HOME
bar/baz
foo/bar
foo/baz
getantidote/zsh-defer
git@fakegitsite.com:foo/qux
ohmy/ohmy
%
```

### Directories

`antidote list --dirs`

```zsh
% antidote list --dirs | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/fakegitsite.com/bar/baz
$ANTIDOTE_HOME/fakegitsite.com/foo/bar
$ANTIDOTE_HOME/fakegitsite.com/foo/baz
$ANTIDOTE_HOME/fakegitsite.com/foo/qux
$ANTIDOTE_HOME/fakegitsite.com/getantidote/zsh-defer
$ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy
%
```

### URLs

`antidote list --url`

```zsh
% antidote list --url
git@fakegitsite.com:foo/qux
https://fakegitsite.com/bar/baz
https://fakegitsite.com/foo/bar
https://fakegitsite.com/foo/baz
https://fakegitsite.com/getantidote/zsh-defer
https://fakegitsite.com/ohmy/ohmy
%
```

### Full

`antidote list`

```zsh
% antidote list | subenv ANTIDOTE_HOME
git@fakegitsite.com:foo/qux                                      $ANTIDOTE_HOME/fakegitsite.com/foo/qux
https://fakegitsite.com/bar/baz                                  $ANTIDOTE_HOME/fakegitsite.com/bar/baz
https://fakegitsite.com/foo/bar                                  $ANTIDOTE_HOME/fakegitsite.com/foo/bar
https://fakegitsite.com/foo/baz                                  $ANTIDOTE_HOME/fakegitsite.com/foo/baz
https://fakegitsite.com/getantidote/zsh-defer                    $ANTIDOTE_HOME/fakegitsite.com/getantidote/zsh-defer
https://fakegitsite.com/ohmy/ohmy                                $ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy
%
```

### JSONL

`antidote list --jsonl`

```zsh
% antidote list --jsonl | subenv ANTIDOTE_HOME
{"url":"https://fakegitsite.com/bar/baz","short_name":"bar/baz","type":"repo","path":"$ANTIDOTE_HOME/fakegitsite.com/bar/baz"}
{"url":"https://fakegitsite.com/foo/bar","short_name":"foo/bar","type":"repo","path":"$ANTIDOTE_HOME/fakegitsite.com/foo/bar"}
{"url":"https://fakegitsite.com/foo/baz","short_name":"foo/baz","type":"repo","path":"$ANTIDOTE_HOME/fakegitsite.com/foo/baz"}
{"url":"git@fakegitsite.com:foo/qux","short_name":"git@fakegitsite.com:foo/qux","type":"repo","path":"$ANTIDOTE_HOME/fakegitsite.com/foo/qux"}
{"url":"https://fakegitsite.com/getantidote/zsh-defer","short_name":"getantidote/zsh-defer","type":"repo","path":"$ANTIDOTE_HOME/fakegitsite.com/getantidote/zsh-defer"}
{"url":"https://fakegitsite.com/ohmy/ohmy","short_name":"ohmy/ohmy","type":"repo","path":"$ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy"}
%
```

## Teardown

```zsh
% t_teardown
%
```
