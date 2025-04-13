# antidote bundle helper tests

## Setup

```zsh
% TESTDATA=$PWD/tests/testdata
% source ./tests/__init__.zsh
% t_setup
% antidote-bundle -h &>/dev/null
%
```

## Awk filter repos

The repo parser pulls a list of all git URLs in a bundle file so that we can clone missing ones in parallel.

```zsh
% __antidote_bulk_clone $TESTDATA/.zsh_plugins_repos.txt
antidote-script --kind clone --branch baz foobar/foobar &
antidote-script --kind clone bar/baz &
antidote-script --kind clone getantidote/zsh-defer &
antidote-script --kind clone git@github.com:user/repo &
antidote-script --kind clone http://github.com/user/repo.git &
antidote-script --kind clone https://github.com/foo/baz &
antidote-script --kind clone https://github.com/foo/qux &
antidote-script --kind clone https://github.com/user/repo &
antidote-script --kind clone user/repo &
wait
%
```

Test empty

```zsh
% __antidote_bulk_clone $TESTDATA/.zsh_plugins_empty.txt
wait
%
```

## Bundle parser

Parse a simple repo:

```zsh
% echo foo/bar | __antidote_parse_bundles
antidote-script foo/bar
%
```

```zsh
% echo 'https://github.com/foo/bar path:lib branch:dev' | __antidote_parse_bundles
antidote-script --branch dev --path lib https://github.com/foo/bar
% echo 'git@github.com:foo/bar.git kind:clone branch:main' | __antidote_parse_bundles
antidote-script --branch main --kind clone git@github.com:foo/bar.git
% echo 'foo/bar kind:fpath abc:xyz' | __antidote_parse_bundles
antidote-script --abc xyz --kind fpath foo/bar
% echo 'foo/bar path:plugins/myplugin kind:path  # trailing comment' | __antidote_parse_bundles
antidote-script --kind path --path plugins/myplugin foo/bar
%
```

```zsh
% print 'foo/bar kind:defer\nbar/baz kind:defer\nbaz/qux kind:defer' | __antidote_parse_bundles
antidote-script --kind defer foo/bar
antidote-script --kind defer --skip-load-defer bar/baz
antidote-script --kind defer --skip-load-defer baz/qux
%
```

Handle funky whitespace

```zsh
% cr=$'\r'; lf=$'\n'; tab=$'\t'
% echo "foo/bar${tab}kind:path${cr}${lf}" | __antidote_parse_bundles
antidote-script --kind path foo/bar
%
```

The bundle parser is an awk script that turns the bundle DSL into antidote-script statements.

```zsh
% __antidote_parse_bundles < $ZDOTDIR/.zsh_plugins.txt
antidote-script ~/foo/bar
antidote-script --path plugins/myplugin \$ZSH_CUSTOM
antidote-script foo/bar
antidote-script git@github.com:foo/qux.git
antidote-script --kind clone getantidote/zsh-defer
antidote-script --kind zsh foo/bar
antidote-script --kind fpath foo/bar
antidote-script --kind path foo/bar
antidote-script --path lib ohmy/ohmy
antidote-script --path plugins/extract ohmy/ohmy
antidote-script --kind defer --path plugins/magic-enter ohmy/ohmy
antidote-script --path custom/themes/pretty.zsh-theme ohmy/ohmy
%
```

## Teardown

```zsh
% t_teardown
%
```
