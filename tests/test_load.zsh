0=${(%):-%x}
@echo "=== ${0:t:r} ==="

autoload -Uz ${0:a:h}/functions/setup && setup

BUNDLEFILE=$TEMP_HOME/.zsh_plugins.txt
STATICFILE="${BUNDLEFILE:r}.zsh"
cp "${0:a:h}/misc/zsh_plugins.txt" "$BUNDLEFILE"

@test "no static file exists" ! -f "$STATICFILE"

# we need to redirect @echo fd3 output to somewhere
# logs, /dev/null, &1...
3>$ZTAP_LOG_HOME/${0:t:r}.git.log 2>$ZTAP_LOG_HOME/${0:t:r}.err antidote load "$BUNDLEFILE"
@test "antidote load succeeds" $? -eq 0

@test "a static file now exists" -f "$STATICFILE"

teardown
