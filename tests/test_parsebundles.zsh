0=${(%):-%x}
@echo "=== ${0:t:r} ==="

autoload -Uz ${0:a:h}/functions/setup && setup

expected=( repo foo/bar )
expected="$(__antidote_join $'\t' $expected)"
actual="$(_antidote_parsebundles foo/bar)"
@test "parsing bundle foo/bar => $expected" "$actual" = "$expected"

expected=( repo foo/bar kind fpath abc xyz )
expected="$(__antidote_join $'\t' $expected)"
actual="$(_antidote_parsebundles foo/bar kind:fpath abc:xyz)"
@test "parsing bundle 'foo/bar kind:fpath abc:xyz'" "$actual" = "$expected"

expected=$(cat <<'EOBUNDLES'
repo foo/bar kind fpath abc xyz
repo bar/baz
EOBUNDLES
)
bundle='foo/bar kind:fpath abc:xyz\nbar/baz'
actual=$(_antidote_parsebundles $bundle 2>&1)
actual=${actual//$'\t'/ }
@test "parsing quoted bundle string with newline sep" "$actual" = "$expected"

expected="antidote: bad annotation 'whoops'."
actual="$(_antidote_parsebundles 'foo/bar whoops' 2>&1)"
@test "parsing 'foo/bar whoops' prints error' => $expected" "$actual" = "$expected"

expected=$(cat <<'EOBUNDLES'
repo foo/bar kind fpath
repo foo/baz branch dev
EOBUNDLES
)
actual="$(_antidote_parsebundles <<EOBUNDLES
# comments
foo/bar kind:fpath
foo/baz branch:dev
EOBUNDLES
)"
actual=${actual//$'\t'/ }
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
repo foo/bar
repo foo/baz
repo bar/baz kind clone
repo baz/foo branch main kind fpath
EOBUNDLES
)
#actual="$(echo $clrf_bundlestr | _antidote_parsebundles)"
actual="$(printf "%s\r\n" "$bundle_list[@]" | _antidote_parsebundles)"
actual=${actual//$'\t'/ }
@test "parsing complex bundle with crlf" "$actual" = "$expected"

teardown
