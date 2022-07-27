0=${(%):-%x}
@echo "=== ${0:t:r} ==="

autoload -Uz ${0:a:h}/functions/setup && setup
autoload -Uz $PRJ_HOME/functions/_antidote_parsebundles

expected="typeset -A bundle=( [kind]=zsh [repo]=foo/bar )"
actual="$(_antidote_parsebundles foo/bar)"
@test "parsing bundle foo/bar => $expected" "$actual" = "$expected"

expected=$(cat <<'EOBUNDLES'
typeset -A bundle=( [kind]=fpath [repo]=foo/bar )
typeset -A bundle=( [branch]=dev [kind]=zsh [repo]=foo/baz )
EOBUNDLES
)
actual="$(_antidote_parsebundles <<EOBUNDLES
# comments
foo/bar kind:fpath
foo/baz branch:dev
EOBUNDLES
)"
@test "parsing multiline bundle with comments" "$actual" = "$expected"

bundle_list=(
  "# header comment"
  "foo/bar"
  ""
  "foo/baz  # trailing comment baz"
  "bar/baz kind:clone"
  "baz/foo branch:main kind:fpath"
)
clrf_bundlestr=$(printf "%s\r\n" "$bundle_list[@]")
expected=$(cat <<'EOBUNDLES'
typeset -A bundle=( [kind]=zsh [repo]=foo/bar )
typeset -A bundle=( [kind]=zsh [repo]=foo/baz )
typeset -A bundle=( [kind]=clone [repo]=bar/baz )
typeset -A bundle=( [branch]=main [kind]=fpath [repo]=baz/foo )
EOBUNDLES
)
actual="$(echo $clrf_bundlestr | _antidote_parsebundles)"
@test "parsing complex bundle with crlf" "$actual" = "$expected"

teardown
