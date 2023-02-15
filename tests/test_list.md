# antidote list tests

## Setup

```zsh
% TESTDIR=$PWD/tests
% source $TESTDIR/scripts/setup.zsh
%
```

## List Command

### Short

`antidote list --short`

```zsh
% antidote list --short | subvar ANTIDOTE_HOME
bar/baz
foo/bar
git@github.com:baz/qux
ohmy/ohmy
romkatv/zsh-defer
%
```

### Directories

`antidote list --dirs`

```zsh
% antidote list --dirs | subvar ANTIDOTE_HOME
$ANTIDOTE_HOME/git-AT-github.com-COLON-baz-SLASH-qux
$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-bar-SLASH-baz
$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar
$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmy-SLASH-ohmy
$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-romkatv-SLASH-zsh-defer
%
```

### Full

`antidote list`

```zsh
% antidote list | subvar ANTIDOTE_HOME
git@github.com:baz/qux                                           $ANTIDOTE_HOME/git-AT-github.com-COLON-baz-SLASH-qux
https://github.com/bar/baz                                       $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-bar-SLASH-baz
https://github.com/foo/bar                                       $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar
https://github.com/ohmy/ohmy                                     $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmy-SLASH-ohmy
https://github.com/romkatv/zsh-defer                             $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-romkatv-SLASH-zsh-defer
%
```

## Teardown

```zsh
% t_teardown
%
```
