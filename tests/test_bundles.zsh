0=${(%):-%x}
@echo "=== ${0:t:r} ==="

# bundles is just an alias for bundle, so we just need to test that it properly passes
# arguments, or redirected/piped input. Everything else should be tested in
# 'antidote bundle' tests.
autoload -Uz ${0:a:h}/functions/setup && setup

antidote bundles &>/dev/null
@test "'antidote bundles' succeeds" $? -eq 0

msg="$(antidote bundles 2>&1)"
@test "'antidote bundles' prints nothing" -z "$msg"

expected=$(cat <<EOBUNDLES
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar )
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar/bar.plugin.zsh
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-baz )
EOBUNDLES
)
actual=$(antidote bundles 2>/dev/null 3>/dev/null <<EOBUNDLES
# ensure comments and blank lines work

foo/bar

foo/baz kind:fpath
EOBUNDLES
)
@test "'antidote bundles' with heredoc works" "$actual" = "$expected"

teardown
