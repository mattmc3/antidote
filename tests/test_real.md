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

### Config

```zsh
% zstyle ':antidote:bundle:*' zcompile 'yes'
%
```

### Bundle

Clone and generate bundle script

```zsh
% antidote bundle <$TESTDATA/.zsh_plugins.txt >$ZDOTDIR/.zsh_plugins.zsh 2>/dev/null
% cat $ZDOTDIR/.zsh_plugins.zsh | subenv ANTIDOTE_HOME  #=> --file testdata/real/.zsh_plugins.zsh
%
```

Check to see that everything cloned

```zsh
% antidote list | subenv ANTIDOTE_HOME  #=> --file testdata/real/repo-list.txt
%
```

Test that everything compiled

```zsh
% zwcfiles=($(ls $(antidote home)/**/*.zwc(N) | wc -l))
% test $zwcfiles -gt 100 #=> --exit 0
%
```

Test that everything updated

```zsh
% rm -rf -- $(antidote home)/**/*.zwc(N)
% antidote update &>/dev/null
% zwcfiles=($(ls $(antidote home)/**/*.zwc(N) | wc -l))
% test $zwcfiles -gt 100 #=> --exit 0
%
```

Check to see that branch:br annotations properly changed the cloned branch

```zsh
% branched_plugin="$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-mattmc3-SLASH-antidote"
% git -C $branched_plugin branch --show-current 2>/dev/null
pz
%
```

Test that `antidote purge --all` aborts when told "no".

```zsh
% function test_exists { [[ -e "$1" ]] }
% zstyle ':antidote:purge:all' answer 'n'
% antidote purge --all                        #=> --exit 1
% antidote list | subenv ANTIDOTE_HOME        #=> --file testdata/real/repo-list.txt
% antidote list | wc -l | awk '{print $1}'
15
% test_exists $ZDOTDIR/.zsh_plugins.zsh(.N)   #=> --exit 0
% test_exists $ZDOTDIR/.zsh_plugins*.bak(.N)  #=> --exit 1
%
```

Test that `antidote purge --all` does the work when told "yes".

```zsh
% function test_exists { [[ -e "$1" ]] }
% zstyle ':antidote:purge:all' answer 'y'
% antidote purge --all | tail -n 1           #=> --exit 0
Antidote purge complete. Be sure to start a new Zsh session.
% antidote list | wc -l | awk '{print $1}'
0
% test_exists $ZDOTDIR/.zsh_plugins.zsh(.N)   #=> --exit 1
% test_exists $ZDOTDIR/.zsh_plugins*.bak(.N)  #=> --exit 0
%
```

### Teardown

```zsh
% zstyle -d ':antidote:purge:all' answer
% t_teardown
%
```

## CRLF testing

### Redo setup

```zsh
% TESTDATA=$PWD/tests/testdata/real
% source ./tests/_setup.zsh
% t_setup_real
%
```

Clone and generate bundle script

```zsh
% antidote bundle <$TESTDATA/.zsh_plugins.crlf.txt >$ZDOTDIR/.zsh_plugins.zsh 2>/dev/null
% cat $ZDOTDIR/.zsh_plugins.zsh | subenv ANTIDOTE_HOME
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-rupa-SLASH-z )
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-rupa-SLASH-z/z.sh
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-syntax-highlighting )
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-completions )
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-completions/zsh-completions.plugin.zsh
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-autosuggestions )
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-autosuggestions/zsh-autosuggestions.plugin.zsh
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-history-substring-search )
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-history-substring-search/zsh-history-substring-search.plugin.zsh
%
```

Check to see that everything cloned

```zsh
% antidote list | subenv ANTIDOTE_HOME
https://github.com/rupa/z                                        $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-rupa-SLASH-z
https://github.com/zsh-users/zsh-autosuggestions                 $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-autosuggestions
https://github.com/zsh-users/zsh-completions                     $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-completions
https://github.com/zsh-users/zsh-history-substring-search        $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-history-substring-search
https://github.com/zsh-users/zsh-syntax-highlighting             $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-syntax-highlighting
%
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
