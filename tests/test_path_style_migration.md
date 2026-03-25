# antidote path-style migration tests

When upgrading from v1 (escaped path-style) to v2 (full path-style), existing clones
should be reused rather than duplicated. See https://github.com/mattmc3/antidote/issues/245.

## Setup

```zsh
% source ./tests/__init__.zsh
% t_setup
% function bundle_dir() { antidote __private__ bundle_dir "$@"; }
%
```

## Reuse existing clones

If a clone already exists under a different path-style, `bundle_dir` returns it
instead of computing a new path.

Escaped clone found when path-style is full:

```zsh
% escaped_dir=$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-fakegitsite.com-SLASH-foo-SLASH-bar
% command mkdir -p $escaped_dir/.git
% zstyle ':antidote:bundle' path-style full
% bundle_dir foo/bar | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-fakegitsite.com-SLASH-foo-SLASH-bar
% test -d $ANTIDOTE_HOME/fakegitsite.com/foo/bar  #=> --exit 1
% command rm -rf $escaped_dir
%
```

Short (friendly-name) clone found when path-style is full:

```zsh
% short_dir=$ANTIDOTE_HOME/foo/bar
% command mkdir -p $short_dir/.git
% zstyle ':antidote:bundle' path-style full
% bundle_dir foo/bar | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/foo/bar
% test -d $ANTIDOTE_HOME/fakegitsite.com/foo/bar  #=> --exit 1
% command rm -rf $short_dir
%
```

SSH URLs use a different escaped format (`git-AT-` instead of `https-COLON-`):

```zsh
% escaped_ssh_dir=$ANTIDOTE_HOME/git-AT-fakegitsite.com-COLON-foo-SLASH-qux
% command mkdir -p $escaped_ssh_dir/.git
% zstyle ':antidote:bundle' path-style full
% bundle_dir git@fakegitsite.com:foo/qux | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/git-AT-fakegitsite.com-COLON-foo-SLASH-qux
% test -d $ANTIDOTE_HOME/fakegitsite.com/foo/qux  #=> --exit 1
% command rm -rf $escaped_ssh_dir
%
```

Short clone found when path-style is full (different repo):

```zsh
% short_dir=$ANTIDOTE_HOME/bar/baz
% command mkdir -p $short_dir/.git
% zstyle ':antidote:bundle' path-style full
% bundle_dir bar/baz | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/bar/baz
% test -d $ANTIDOTE_HOME/fakegitsite.com/bar/baz  #=> --exit 1
% command rm -rf $short_dir
%
```

## Duplicate cleanup

`bundle_dir` itself has no side effects. `bundle_dir_cleanup` removes legacy dupes
when the preferred path exists.

```zsh
% function bundle_dir_cleanup() { antidote __private__ bundle_dir_cleanup "$@"; }
% escaped_dir=$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-fakegitsite.com-SLASH-foo-SLASH-bar
% full_dir=$ANTIDOTE_HOME/fakegitsite.com/foo/bar
% command mkdir -p $escaped_dir/.git
% command mkdir -p $full_dir/.git
% zstyle ':antidote:bundle' path-style full
% # bundle_dir returns preferred but does not delete the legacy clone
% bundle_dir foo/bar | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/fakegitsite.com/foo/bar
% test -d $escaped_dir  #=> --exit 0
% # bundle_dir_cleanup removes the legacy clone
% bundle_dir_cleanup foo/bar
% test -d $escaped_dir  #=> --exit 1
% test -d $full_dir  #=> --exit 0
% command rm -rf $full_dir
%
```

When all three styles exist, only the preferred survives after cleanup:

```zsh
% escaped_dir=$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-fakegitsite.com-SLASH-foo-SLASH-bar
% short_dir=$ANTIDOTE_HOME/foo/bar
% full_dir=$ANTIDOTE_HOME/fakegitsite.com/foo/bar
% command mkdir -p $escaped_dir/.git $short_dir/.git $full_dir/.git
% zstyle ':antidote:bundle' path-style full
% bundle_dir_cleanup foo/bar
% test -d $full_dir     #=> --exit 0
% test -d $escaped_dir  #=> --exit 1
% test -d $short_dir    #=> --exit 1
% command rm -rf $full_dir
%
```

## New clones use current path-style

When no clone exists under any style, the current path-style is used.

```zsh
% zstyle ':antidote:bundle' path-style full
% bundle_dir foo/bar | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/fakegitsite.com/foo/bar
% zstyle ':antidote:bundle' path-style short
% bundle_dir foo/bar | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/foo/bar
% zstyle ':antidote:bundle' path-style escaped
% bundle_dir foo/bar | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-fakegitsite.com-SLASH-foo-SLASH-bar
% zstyle ':antidote:bundle' path-style full
%
```

## Escaped to full

Simulate a v1 user upgrading to v2 — `antidote list` should not show dupes.

```zsh
% zstyle ':antidote:bundle' path-style escaped
% antidote bundle foo/bar &>/dev/null
% antidote bundle bar/baz &>/dev/null
% zstyle ':antidote:bundle' path-style full
% antidote bundle foo/bar &>/dev/null
% antidote bundle bar/baz &>/dev/null
% antidote list | wc -l | awk '{print $1}'
2
% command rm -rf $ANTIDOTE_HOME/*
%
```

## Short to full

Bundle with friendly names, switch to full — original clone is kept.

```zsh
% zstyle ':antidote:bundle' path-style short
% antidote bundle foo/bar &>/dev/null
% test -d $ANTIDOTE_HOME/foo/bar  #=> --exit 0
% zstyle ':antidote:bundle' path-style full
% antidote bundle foo/bar &>/dev/null
% test -d $ANTIDOTE_HOME/fakegitsite.com/foo/bar  #=> --exit 1
% test -d $ANTIDOTE_HOME/foo/bar  #=> --exit 0
% command rm -rf $ANTIDOTE_HOME/*
%
```

## Full to escaped

Switching back to escaped reuses the existing full clone.

```zsh
% zstyle ':antidote:bundle' path-style full
% antidote bundle foo/bar &>/dev/null
% test -d $ANTIDOTE_HOME/fakegitsite.com/foo/bar  #=> --exit 0
% zstyle ':antidote:bundle' path-style escaped
% antidote bundle foo/bar &>/dev/null
% test -d $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-fakegitsite.com-SLASH-foo-SLASH-bar  #=> --exit 1
% test -d $ANTIDOTE_HOME/fakegitsite.com/foo/bar  #=> --exit 0
% command rm -rf $ANTIDOTE_HOME/*
%
```

## Full to short

Switching to short reuses the existing full clone.

```zsh
% zstyle ':antidote:bundle' path-style full
% antidote bundle foo/bar &>/dev/null
% test -d $ANTIDOTE_HOME/fakegitsite.com/foo/bar  #=> --exit 0
% zstyle ':antidote:bundle' path-style short
% antidote bundle foo/bar &>/dev/null
% test -d $ANTIDOTE_HOME/foo/bar  #=> --exit 1
% test -d $ANTIDOTE_HOME/fakegitsite.com/foo/bar  #=> --exit 0
% command rm -rf $ANTIDOTE_HOME/*
%
```

## Teardown

```zsh
% t_teardown
%
```
