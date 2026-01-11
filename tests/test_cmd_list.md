# antidote list tests

## Setup

```zsh
% source ./tests/__init__.zsh
% t_setup
%
```

## List Command

### Short

`antidote list --short`

```zsh
% antidote list --short | subenv ANTIDOTE_HOME
foo/bar
foo/baz
getantidote/zsh-defer
git@github.com:foo/qux
ohmy/ohmy
%
```

### Directories

`antidote list --dirs`

```zsh
% antidote list --dirs | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/foo/bar
$ANTIDOTE_HOME/foo/baz
$ANTIDOTE_HOME/foo/qux
$ANTIDOTE_HOME/getantidote/zsh-defer
$ANTIDOTE_HOME/ohmy/ohmy
%
```

### URLs

`antidote list --url`

```zsh
% antidote list --url
git@github.com:foo/qux
https://github.com/foo/bar
https://github.com/foo/baz
https://github.com/getantidote/zsh-defer
https://github.com/ohmy/ohmy
%
```

### Full

`antidote list`

```zsh
% antidote list | subenv ANTIDOTE_HOME
git@github.com:foo/qux                                           $ANTIDOTE_HOME/foo/qux
https://github.com/foo/bar                                       $ANTIDOTE_HOME/foo/bar
https://github.com/foo/baz                                       $ANTIDOTE_HOME/foo/baz
https://github.com/getantidote/zsh-defer                         $ANTIDOTE_HOME/getantidote/zsh-defer
https://github.com/ohmy/ohmy                                     $ANTIDOTE_HOME/ohmy/ohmy
%
```

### JSONL

`antidote list --jsonl`

```zsh
% antidote list --jsonl | subenv ANTIDOTE_HOME
{"url":"https://github.com/foo/bar","short_name":"foo/bar","type":"repo","path":"$ANTIDOTE_HOME/foo/bar"}
{"url":"https://github.com/foo/baz","short_name":"foo/baz","type":"repo","path":"$ANTIDOTE_HOME/foo/baz"}
{"url":"git@github.com:foo/qux","short_name":"git@github.com:foo/qux","type":"repo","path":"$ANTIDOTE_HOME/foo/qux"}
{"url":"https://github.com/getantidote/zsh-defer","short_name":"getantidote/zsh-defer","type":"repo","path":"$ANTIDOTE_HOME/getantidote/zsh-defer"}
{"url":"https://github.com/ohmy/ohmy","short_name":"ohmy/ohmy","type":"repo","path":"$ANTIDOTE_HOME/ohmy/ohmy"}
%
```

## Teardown

```zsh
% t_teardown
%
```
