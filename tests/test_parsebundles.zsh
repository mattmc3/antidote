#!/usr/bin/env zsh
0=${(%):-%x}
autoload -Uz ${0:A:h}/functions/testinit && testinit
ztap_header "${0:t:r}"

# setup
source $BASEDIR/antidote.zsh

() {
  local expected actual
  expected=( repo foo/bar )
  expected="$(__antidote_join $'\t' $expected)"
  actual="$(__antidote_parsebundles foo/bar)"
  @test "parsing bundle foo/bar => $expected" "$actual" = "$expected"
}

() {
  local actual expected bundle exitcode
  bundle='foo/bar whoops'
  expected="antidote: bad annotation 'whoops'."
  actual=$(__antidote_parsebundles $bundle 2>&1)
  exitcode=$?
  @test "parse bad bundle fails" $exitcode -ne 0
  @test "parse bad bundle prints error" "$actual" = "$expected"
}

() {
  local actual expected testdata i bundle
  local cr lf tab
  cr=$'\r'; lf=$'\n'; tab=$'\t'
  local testdata=(
    # repo only
         'foo/bar'
    'repo foo/bar'
    # repo and annotations
         'https://github.com/foo/bar path:lib branch:dev'
    'repo https://github.com/foo/bar path lib branch dev'
         'git@github.com:foo/bar.git kind:clone branch:main'
    'repo git@github.com:foo/bar.git kind clone branch main'
         'foo/bar kind:fpath abc:xyz'
    'repo foo/bar kind fpath abc xyz'
    # repo and different whitespace
    #     "foo/bar${tab}kind:path${cr}${lf}"
    #'repo foo/bar kind path'
    # comments
         'foo/bar path:plugins/myplugin kind:path  # trailing comment'
    'repo foo/bar path plugins/myplugin kind path'
    '# comment'
    ''
  )
  for i in $(seq 1 2 $#testdata); do
    bundle=$testdata[i]
    expected=$testdata[(( i + 1 ))]
    actual="$(__antidote_parsebundles $bundle)"
    actual=${actual//$'\t'/ }
    @test "parse bundle: '$bundle'" "${(q-)actual}" = "${(q-)expected}"
  done
}

() {
  local expected actual bundle
  expected=$(cat <<'EOBUNDLES'
repo foo/bar kind fpath abc xyz
repo bar/baz
EOBUNDLES
  )
  bundle='foo/bar kind:fpath abc:xyz\nbar/baz'
  actual=$(__antidote_parsebundles $bundle 2>&1)
  actual=${actual//$'\t'/ }
  @test "parsing quoted bundle string with newline sep" "$actual" = "$expected"
}

() {
  local expected actual
  expected=$(cat <<'EOBUNDLES'
repo foo/bar kind fpath
repo foo/baz branch dev
EOBUNDLES
  )
  actual="$(__antidote_parsebundles <<EOBUNDLES
# comments
foo/bar kind:fpath
foo/baz branch:dev
EOBUNDLES
  )"
  actual=${actual//$'\t'/ }
  @test "parsing multiline bundle with comments" "$actual" = "$expected"
}

() {
  local expected actual bundle_list
  bundle_list=(
    "# header comment"
    "foo/bar"
    ""
    "foo/baz  # trailing comment baz"
    "bar/baz kind:clone"
    "baz/foo branch:main kind:fpath"
  )
  expected=$(cat <<'EOBUNDLES'
repo foo/bar
repo foo/baz
repo bar/baz kind clone
repo baz/foo branch main kind fpath
EOBUNDLES
  )
  actual="$(printf "%s\r\n" "$bundle_list[@]" | __antidote_parsebundles)"
  actual=${actual//$'\t'/ }
  @test "parsing complex bundle with crlf" "$actual" = "$expected"
}

ztap_footer
