# antidote bundle helper tests

## Setup

```zsh
% source $PWD/tests/scripts/setup.zsh
%
```

## Test bundle command

Many 'bundle' tests could just as well just be 'script' tests, so we rely on
'test_script.md' to find scripting issues and use this to test actual bundling,
or things not handled by 'antidote script'. You can think of 'antidote script' as
handling a single bundle, and 'antidote bundle' handling them in bulk.

### General

```zsh
% # antidote bundle
%
```

```zsh
% antidote bundle <$ZDOTDIR/.zsh_plugins.txt >$ZDOTDIR/.zsh_plugins.zsh
%
```

### Multiple ways to call bundle

Test \|piping, \<redirection, and --args

```zsh
% antidote bundle foo/bar | subvar ANTIDOTE_HOME  #=> --file testdata/script-foobar.zsh
% echo 'foo/bar' | antidote bundle | subvar ANTIDOTE_HOME  #=> --file testdata/script-foobar.zsh
% echo 'foo/bar' >$ZDOTDIR/.zsh_plugins_simple.txt
% antidote bundle <$ZDOTDIR/.zsh_plugins_simple.txt | subvar ANTIDOTE_HOME  #=> --file testdata/script-foobar.zsh
%
```

## Teardown

```zsh
% t_teardown
%
```
