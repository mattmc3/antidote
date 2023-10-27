# antidote main tests

## Setup

```zsh
% source ./tests/_setup.zsh
% source ./antidote.zsh
%
```

## Test main

Main is core to everything, so we don't need to test much here.

```zsh
% antidote-main --version &>/dev/null  #=> --exit 0
%
```

## Lazy config

Tests for lazy-loading antidote.

- Fix [#54](https://github.com/mattmc3/antidote/issues/54)

```zsh
% # Unload antidote
% echo $+functions[antidote-main]
1
% t_teardown
% echo $+functions[antidote-main]
0
% # Now, lazy load it and make sure it works
% autoload -Uz $PWD/antidote
% antidote -v &>/dev/null; echo $?
0
% # Now, tear down again
% echo $+functions[antidote-main]
1
% t_teardown
% echo $+functions[antidote-main]
0
% # Now, lazy load from the functions dir
% autoload -Uz $PWD/functions/antidote
% antidote -v &>/dev/null; echo $?
0
% echo $+functions[antidote-main]
1
%
```

## Teardown

```zsh
% t_teardown
%
```
