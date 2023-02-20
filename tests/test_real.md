# antidote tests for real

## antidote bundle

### Setup

```zsh
% TESTDATA=$PWD/tests/testdata/real
% source ./tests/_setup.zsh
% # do it for real!
% t_setup_real
%
```

### Bundle

Clone and generate bundle script

```zsh
$ antidote bundle <$TESTDATA/.zsh_plugins.txt >$ZDOTDIR/.zsh_plugins.zsh 2>/dev/null
$ cat $ZDOTDIR/.zsh_plugins.zsh | subenv ANTIDOTE_HOME  #=> --file testdata/real/.zsh_plugins.zsh
$
```

Check to see that everything cloned

```zsh
$ antidote list | subenv ANTIDOTE_HOME  #=> --file testdata/real/repo-list.txt
$
```

Check to see that branch:br annotations properly changed the cloned branch

```zsh
$ branched_plugin="$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-mattmc3-SLASH-antidote"
$ git -C $branched_plugin branch --show-current 2>/dev/null
pz
$
```

### Teardown

```zsh
% t_teardown
%
```

## antidote load

### Redo setup

```zsh
% TESTDATA=$PWD/tests/testdata/real
% source ./tests/_setup.zsh
% t_setup_real
%
```

### Load

Load rupa/z

```zsh
% zstyle ':antidote:bundle' use-friendly-names on
% echo "rupa/z" > $ZDOTDIR/.zsh_plugins.txt
% antidote load 2>&1
# antidote cloning rupa/z...
% echo $+aliases[z]
1
% wc -l <$ZDOTDIR/.zsh_plugins.zsh | sed 's/ //g'
2
% (( ! $+aliases[z] )) || unalias z
%
```

Load re-generates .zsh_plugins.zsh when .zsh_plugins.txt changes

```zsh
% compdir=$ANTIDOTE_HOME/zsh-users/zsh-completions/src
% (( $fpath[(Ie)$compdir] )) || echo "completions are not in fpath"
completions are not in fpath
% echo $+aliases[z]
0
%
```

...add a new plugin

```zsh
% wc -l <$ZDOTDIR/.zsh_plugins.txt | sed 's/ //g'
1
% cat $ZDOTDIR/.zsh_plugins.zsh | subenv ANTIDOTE_HOME
fpath+=( $ANTIDOTE_HOME/rupa/z )
source $ANTIDOTE_HOME/rupa/z/z.sh
% echo "zsh-users/zsh-completions path:src kind:fpath" >> $ZDOTDIR/.zsh_plugins.txt
% # static cache file hasn't changed yet
% cat $ZDOTDIR/.zsh_plugins.zsh | subenv ANTIDOTE_HOME
fpath+=( $ANTIDOTE_HOME/rupa/z )
source $ANTIDOTE_HOME/rupa/z/z.sh
%
```

...now do `antidote load` and show that it actually loaded all plugins

```zsh
% antidote load 2>&1
# antidote cloning zsh-users/zsh-completions...
% cat $ZDOTDIR/.zsh_plugins.zsh | subenv ANTIDOTE_HOME
fpath+=( $ANTIDOTE_HOME/rupa/z )
source $ANTIDOTE_HOME/rupa/z/z.sh
fpath+=( $ANTIDOTE_HOME/zsh-users/zsh-completions/src )
% echo $+aliases[z]
1
% (( $fpath[(Ie)$compdir] )) && echo "completions are in fpath"
completions are in fpath
%
% wc -l <$ZDOTDIR/.zsh_plugins.zsh | sed 's/ //g'
3
%
```

### Teardown

```zsh
% t_teardown
%
```
