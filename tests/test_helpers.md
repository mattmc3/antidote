# antidote helper tests

## Setup

```zsh
% source ./tests/__init__.zsh
% t_setup
%
```

## Safe removal

Appease my paranoia and ensure that you can't remove a path you shouldn't be able to:

```zsh
% function del() { antidote __private__ del "$@"; }
% del -- /foo/bar
antidote: Blocked attempt to rm path: '/foo/bar'.
%
```

## Bundle type

```zsh
% function bundle_type() { antidote __private__ bundle_type "$@"; }
% bundle_type $T_PRJDIR/antidote.zsh
file
% bundle_type $T_PRJDIR/functions
dir
% bundle_type '$T_PRJDIR/antidote.zsh'
file
% bundle_type \$T_PRJDIR/functions
dir
% bundle_type 'git@fakegitsite.com:foo/bar.git'
ssh_url
% bundle_type 'https://fakegitsite.com/foo/bar'
url
% bundle_type 'https://gist.github.com/someuser/abc123def456'
url
% bundle_type 'https://gist.github.com/someuser/abc123def456.git'
url
% bundle_type 'https://gitlab.com/group/subgroup/repo'
url
% bundle_type 'https://github.com'
url
% bundle_type 'https://github.com.git'
url
% bundle_type 'https:/typo.com/foo/bar.git'
?
% bundle_type ''
empty
% bundle_type '    '
empty
% bundle_type /foo/bar
path
% bundle_type /foobar
path
% bundle_type foobar/
?
% bundle_type '~/foo/bar'
path
% bundle_type '$foo/bar'
path
% bundle_type \$ZDOTDIR/foo
path
% bundle_type \$ZDOTDIR/.zsh_plugins.txt
file
% touch ~/.zshenv
% bundle_type '~/.zshenv'
file
% bundle_type '~/null'
path
% bundle_type foo/bar
repo
% bundle_type bar/baz.git
repo
% bundle_type foo/bar/baz
?
% bundle_type foobar
using_subplugin
% bundle_type foo bar baz
using_subplugin
% bundle_type 'foo bar baz'
?
%
```

## Bundle name

```zsh
% function bundle_name() { antidote __private__ bundle_name "$@"; }
% bundle_name $HOME/.zsh/custom/lib/lib1.zsh
$HOME/.zsh/custom/lib/lib1.zsh
% bundle_name $HOME/.zsh/plugins/myplugin
$HOME/.zsh/plugins/myplugin
% bundle_name 'git@fakegitsite.com:foo/bar.git'
git@fakegitsite.com:foo/bar
% bundle_name 'https://fakegitsite.com/foo/bar'
foo/bar
% bundle_name 'https://gist.github.com/someuser/abc123def456.git'
someuser/abc123def456
% bundle_name 'https://gitlab.com/group/subgroup/repo'
subgroup/repo
% bundle_name 'https:/bad.com/foo/bar.git'
https:/bad.com/foo/bar.git
% bundle_name ''

% bundle_name /foo/bar
/foo/bar
% bundle_name /foobar
/foobar
% bundle_name foobar/
foobar/
% bundle_name '~/foo/bar'
$HOME/foo/bar
% bundle_name '$foo/bar'
$foo/bar
% bundle_name foo/bar
foo/bar
% bundle_name bar/baz.git
bar/baz.git
% bundle_name foo/bar/baz
foo/bar/baz
% bundle_name foobar
foobar
% bundle_name foo bar baz
foo
% bundle_name 'foo bar baz'
foo bar baz
%
```

## Bundle dir by style

```zsh
% function __bundle_dir_by_style() { antidote __private__ __bundle_dir_by_style "$@"; }
% # escaped
% __bundle_dir_by_style "https://fakegitsite.com/foo/bar" escaped | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-fakegitsite.com-SLASH-foo-SLASH-bar
% # full
% __bundle_dir_by_style "https://fakegitsite.com/foo/bar" full | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/fakegitsite.com/foo/bar
% # short
% __bundle_dir_by_style "https://fakegitsite.com/foo/bar" short | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/foo/bar
% # ssh escaped
% __bundle_dir_by_style "git@fakegitsite.com:foo/bar" escaped | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/git-AT-fakegitsite.com-COLON-foo-SLASH-bar
% # ssh full
% __bundle_dir_by_style "git@fakegitsite.com:foo/bar" full | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/fakegitsite.com/foo/bar
% # ssh short
% __bundle_dir_by_style "git@fakegitsite.com:foo/bar" short | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/foo/bar
%
```

## Bundle dir

```zsh
% function bundle_dir() { antidote __private__ bundle_dir "$@"; }
% zstyle ':antidote:bundle' path-style escaped
% # short repo
% bundle_dir foo/bar | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-fakegitsite.com-SLASH-foo-SLASH-bar
% # repo url
% bundle_dir https://fakegitsite.com/foo/bar | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-fakegitsite.com-SLASH-foo-SLASH-bar
% # repo url.git
% bundle_dir https://fakegitsite.com/foo/bar.git | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-fakegitsite.com-SLASH-foo-SLASH-bar
% # repo ssh
% bundle_dir git@fakegitsite.com:foo/bar.git | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/git-AT-fakegitsite.com-COLON-foo-SLASH-bar
% # gist url
% bundle_dir https://gist.github.com/someuser/abc123def456.git | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-gist.github.com-SLASH-someuser-SLASH-abc123def456
% # local dir
% bundle_dir ~/foo/bar | subenv HOME
$HOME/foo/bar
% # another local dir
% bundle_dir $ZDOTDIR/bar/baz | subenv ZDOTDIR
$ZDOTDIR/bar/baz
% zstyle -d ':antidote:bundle' path-style
%
```

Use short names

```zsh
% # short repo - friendly name
% zstyle ':antidote:bundle' path-style short
% bundle_dir foo/bar | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/foo/bar
% # repo url - friendly name
% bundle_dir https://fakegitsite.com/bar/baz | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/bar/baz
% # nested group path preserves all path segments after domain
% bundle_dir https://fakegitsite.com/foo/bar/baz/qux | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/foo/bar/baz/qux
% # ssh repo - friendly name
% bundle_dir git@fakegitsite.com:foo/qux.git | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/foo/qux
% # gist url - friendly name
% bundle_dir https://gist.github.com/someuser/abc123def456.git | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/someuser/abc123def456
% zstyle -d ':antidote:bundle' path-style
%
```

Use full names

```zsh
% zstyle ':antidote:bundle' path-style full
% bundle_dir foo/bar | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/fakegitsite.com/foo/bar
% bundle_dir https://fakegitsite.com/bar/baz | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/fakegitsite.com/bar/baz
% bundle_dir git@fakegitsite.com:foo/qux.git | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/fakegitsite.com/foo/qux
% # gist url
% bundle_dir https://gist.github.com/someuser/abc123def456.git | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/gist.github.com/someuser/abc123def456
% # gitlab nested group url
% bundle_dir https://gitlab.com/group/subgroup/repo | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/gitlab.com/group/subgroup/repo
% zstyle -d ':antidote:bundle' path-style
%
```

Legacy: Use friendly names

```zsh
% # short repos style used to be called "use friendly names"
% zstyle -d ':antidote:bundle' path-style
% zstyle ':antidote:bundle' use-friendly-names on
% bundle_dir foo/bar | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/foo/bar
% # repo url - friendly name
% bundle_dir https://fakegitsite.com/bar/baz | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/bar/baz
% # nested group path preserves all path segments after domain
% bundle_dir https://fakegitsite.com/foo/bar/baz/qux | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/foo/bar/baz/qux
% # ssh repo - friendly name
% bundle_dir git@fakegitsite.com:foo/qux.git | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/foo/qux
% zstyle -d ':antidote:bundle' use-friendly-names
%
```

### To URL

Short repos:

```zsh
% function tourl() { antidote __private__ tourl "$@"; }
% tourl ohmyzsh/ohmyzsh
https://fakegitsite.com/ohmyzsh/ohmyzsh
% tourl sindresorhus/pure
https://fakegitsite.com/sindresorhus/pure
% tourl foo/bar
https://fakegitsite.com/foo/bar
%
```

Proper URLs don't change:

```zsh
% tourl https://github.com/ohmyzsh/ohmyzsh
https://github.com/ohmyzsh/ohmyzsh
% tourl http://github.com/ohmyzsh/ohmyzsh
http://github.com/ohmyzsh/ohmyzsh
% tourl ssh://github.com/ohmyzsh/ohmyzsh
ssh://github.com/ohmyzsh/ohmyzsh
% tourl git://github.com/ohmyzsh/ohmyzsh
git://github.com/ohmyzsh/ohmyzsh
% tourl ftp://github.com/ohmyzsh/ohmyzsh
ftp://github.com/ohmyzsh/ohmyzsh
% tourl git@github.com:sindresorhus/pure.git
git@github.com:sindresorhus/pure.git
%
```

## Short repo name

```zsh
% function short_repo_name() { antidote __private__ short_repo_name "$@"; }
% short_repo_name foo/bar
foo/bar
% short_repo_name https://github.com/foo/bar
foo/bar
% short_repo_name https://github.com/foo/bar.git
foo/bar
% short_repo_name git@github.com:foo/bar.git
git@github.com:foo/bar
% short_repo_name git@github.com:foo/bar
git@github.com:foo/bar
% short_repo_name https://gitlab.com/deep/nested/repo
nested/repo
%
```

## Get cachedir

```zsh
% function get_cachedir() { antidote __private__ get_cachedir "$@"; }
% zstyle ':antidote:test:env' OSTYPE linux-gnu
% get_cachedir | subenv HOME
$HOME/.cache
% get_cachedir antidote | subenv HOME
$HOME/.cache/antidote
% zstyle ':antidote:test:env' OSTYPE darwin23.0
% get_cachedir | subenv HOME
$HOME/Library/Caches
% get_cachedir antidote | subenv HOME
$HOME/Library/Caches/antidote
% zstyle -d ':antidote:test:env' OSTYPE
%
```

## Get cachedir with XDG override

```zsh
% zstyle ':antidote:test:env' OSTYPE linux-gnu
% XDG_CACHE_HOME=/tmp/xdg-cache antidote __private__ get_cachedir
/tmp/xdg-cache
% XDG_CACHE_HOME=/tmp/xdg-cache antidote __private__ get_cachedir antidote
/tmp/xdg-cache/antidote
% zstyle -d ':antidote:test:env' OSTYPE
%
```

## Get datadir

```zsh
% function get_datadir() { antidote __private__ get_datadir "$@"; }
% zstyle ':antidote:test:env' OSTYPE linux-gnu
% get_datadir | subenv HOME
$HOME/.local/share
% get_datadir antidote | subenv HOME
$HOME/.local/share/antidote
% zstyle ':antidote:test:env' OSTYPE darwin23.0
% get_datadir | subenv HOME
$HOME/Library/Application Support
% get_datadir antidote | subenv HOME
$HOME/Library/Application Support/antidote
% zstyle -d ':antidote:test:env' OSTYPE
%
```

## Get datadir with XDG override

```zsh
% zstyle ':antidote:test:env' OSTYPE linux-gnu
% XDG_DATA_HOME=/tmp/xdg-data antidote __private__ get_datadir
/tmp/xdg-data
% XDG_DATA_HOME=/tmp/xdg-data antidote __private__ get_datadir antidote
/tmp/xdg-data/antidote
% zstyle -d ':antidote:test:env' OSTYPE
%
```

## Collect input

```zsh
% function collect_input() { antidote __private__ collect_input "$@"; }
% echo "foo/bar" | collect_input
foo/bar
% printf 'foo/bar\nbar/baz\nbaz/qux\n' | collect_input
foo/bar
bar/baz
baz/qux
% collect_input "foo/bar"
foo/bar
% collect_input $'foo/bar\nbar/baz'
foo/bar
bar/baz
% echo "piped" | collect_input "args-win"
args-win
% collect_input

%
```

## Teardown

```zsh
% t_teardown
%
```
