0=${(%):-%x}
@echo "=== ${0:t:r} ==="

autoload -Uz ${0:a:h}/functions/setup && setup

BUNDLEFILE=$TEMP_HOME/.zsh_plugins.txt
STATICFILE="${BUNDLEFILE:r}.zsh"
cp "${0:a:h}/misc/zsh_plugins.txt" "$BUNDLEFILE"

@test "no static file exists" ! -f "$STATICFILE"

# we need to redirect @echo fd3 output to somewhere
# logs, /dev/null, &1...
>$ZTAP_LOG_HOME/${0:t:r}.log \
2>$ZTAP_LOG_HOME/${0:t:r}.err \
3>$ZTAP_LOG_HOME/${0:t:r}.git.log \
antidote load "$BUNDLEFILE"
@test "antidote load succeeds" $? -eq 0

@test "a static file now exists" -f "$STATICFILE"

expected=$(cat <<'END_HEREDOC'
sourcing foo/bar...
sourcing foo/qux...
sourcing bar/baz...
sourcing baz/devbranch...
sourcing baz/ohmy clipboard lib...
sourcing baz/ohmy extract plugin...
fake zsh-defer source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-baz-SLASH-deferme/deferme.plugin.zsh
sourcing baz/mytheme...
sourcing baz/name.zsh...
sourcing baz/zsh-name...
sourcing baz/shellscript...
sourcing baz/malformed...
END_HEREDOC
)
expected=${expected:gs/\$ANTIDOTE_HOME/$ANTIDOTE_HOME}
actual=$(cat $ZTAP_LOG_HOME/${0:t:r}.log)
@test "plugins were loaded and producted expected output" "$actual" = "$expected"

teardown
