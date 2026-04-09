# antidote bundle helper tests

## Setup

```zsh
% source ./tests/__init__.zsh
% t_setup
% antidote bundle <$ZDOTDIR/.base_test_fixtures.txt &>/dev/null
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
% cat $ZDOTDIR/.zsh_plugins.zsh | subenv  #=> --file testdata/.zsh_plugins.zsh
%
```

### Multiple ways to call bundle

Test \|piping, \<redirection, and --args

```zsh
% ANTIDOTE_HOME=$HOME/.cache/antidote
% antidote bundle foo/bar | subenv ANTIDOTE_HOME  #=> --file testdata/script-foobar.zsh
% echo 'foo/bar' | antidote bundle | subenv ANTIDOTE_HOME  #=> --file testdata/script-foobar.zsh
% echo 'git@fakegitsite.com:foo/qux' >$ZDOTDIR/.zsh_plugins_simple.txt
% antidote bundle <$ZDOTDIR/.zsh_plugins_simple.txt | subenv ANTIDOTE_HOME  #=> --file testdata/script-fooqux.zsh
%
```

### Do the same thing, but with escaped path-style this time

Test \|piping, \<redirection, and --args

```zsh
% zstyle ':antidote:bundle' path-style escaped
% ANTIDOTE_HOME=$HOME/.cache/antibody
% antidote bundle foo/bar 2>/dev/null | subenv ANTIDOTE_HOME  #=> --file testdata/antibody/script-foobar.zsh
% echo 'foo/bar' | antidote bundle | subenv ANTIDOTE_HOME  #=> --file testdata/antibody/script-foobar.zsh
% echo 'git@fakegitsite.com:foo/qux' >$ZDOTDIR/.zsh_plugins_simple.txt
% antidote bundle <$ZDOTDIR/.zsh_plugins_simple.txt 2>/dev/null | subenv ANTIDOTE_HOME  #=> --file testdata/antibody/script-fooqux.zsh
% ANTIDOTE_HOME=$HOME/.cache/antidote
% zstyle ':antidote:bundle' path-style full
%
```

Multiple defers

```zsh
% antidote bundle 'foo/bar kind:defer\nbar/baz kind:defer' | subenv ANTIDOTE_HOME
if ! (( $+functions[zsh-defer] )); then
  fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/getantidote/zsh-defer" )
  source "$ANTIDOTE_HOME/fakegitsite.com/getantidote/zsh-defer/zsh-defer.plugin.zsh"
fi
fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/foo/bar" )
zsh-defer source "$ANTIDOTE_HOME/fakegitsite.com/foo/bar/bar.plugin.zsh"
fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/bar/baz" )
zsh-defer source "$ANTIDOTE_HOME/fakegitsite.com/bar/baz/baz.plugin.zsh"
%
```

## Fails

```zsh
% echo "foo/bar\nfoo/baz kind:whoops" | antidote bundle 2>&1 | grep 'antidote: error:'
# antidote: error: unexpected kind value: 'whoops'
%
```

## Teardown

```zsh
% t_teardown
%
```
