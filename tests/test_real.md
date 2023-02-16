# antidote tests for real

## Setup

```zsh
% TESTDATA=$PWD/tests/testdata/real
% source $PWD/tests/scripts/setup.zsh
% # do it for real!
% t_setup_real
%
```

## Bundle for real

Clone and generate bundle script

```zsh
% antidote bundle <$TESTDATA/.zsh_plugins.txt >$ZDOTDIR/.zsh_plugins.zsh 2>/dev/null
% cat $ZDOTDIR/.zsh_plugins.zsh | subvar ANTIDOTE_HOME  #=> --file testdata/real/.zsh_plugins.zsh
%
```

Check to see that everything cloned

```zsh
% antidote list | subvar ANTIDOTE_HOME  #=> --file testdata/real/repo-list.txt
%
```

Check to see that branch:br annotations properly changed the cloned branch

```zsh
% branched_plugin="$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-mattmc3-SLASH-antidote"
% git -C $branched_plugin branch --show-current 2>/dev/null
pz
%
```

## Teardown

```zsh
% t_teardown
%
```
