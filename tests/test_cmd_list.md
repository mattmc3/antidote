# antidote list tests

## Setup

```zsh
% source ./tests/__init__.zsh
% t_setup
%
```

Ensure there are no bundles:

```zsh
% rm -rf -- $ANTIDOTE_HOME
% antidote list 2>&1 | subenv ANTIDOTE_HOME
antidote: list: no bundles found in '$ANTIDOTE_HOME'
% mkdir -p $ANTIDOTE_HOME
% antidote list 2>&1 | subenv ANTIDOTE_HOME
antidote: list: no bundles found in '$ANTIDOTE_HOME'
%
```

Clone the standard test bundles:

```zsh
% antidote bundle <$ZDOTDIR/.base_test_fixtures.txt &>/dev/null
%
```

## List Command

### Default (Path + URL)

`antidote list` shows path and URL by default (path first):

```zsh
% antidote list | sort | subenv ANTIDOTE_HOME | sed $'s/\t/    /g'
$ANTIDOTE_HOME/fakegitsite.com/bar/baz    https://fakegitsite.com/bar/baz
$ANTIDOTE_HOME/fakegitsite.com/foo/bar    https://fakegitsite.com/foo/bar
$ANTIDOTE_HOME/fakegitsite.com/foo/baz    https://fakegitsite.com/foo/baz
$ANTIDOTE_HOME/fakegitsite.com/foo/qux    git@fakegitsite.com:foo/qux
$ANTIDOTE_HOME/fakegitsite.com/getantidote/zsh-defer    https://fakegitsite.com/getantidote/zsh-defer
$ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy    https://fakegitsite.com/ohmy/ohmy
%
```

Entry count matches expected bundles:

```zsh
% antidote list 2>/dev/null | wc -l | awk '{print $1}'
6
%
```

### URLs

`antidote list --url`

```zsh
% antidote list --url | sort
git@fakegitsite.com:foo/qux
https://fakegitsite.com/bar/baz
https://fakegitsite.com/foo/bar
https://fakegitsite.com/foo/baz
https://fakegitsite.com/getantidote/zsh-defer
https://fakegitsite.com/ohmy/ohmy
%
```

`antidote list -u` (short flag):

```zsh
% antidote list -u | wc -l | awk '{print $1}'
6
%
```

### Directories

`antidote list --dirs`

```zsh
% antidote list --dirs | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/fakegitsite.com/bar/baz
$ANTIDOTE_HOME/fakegitsite.com/foo/bar
$ANTIDOTE_HOME/fakegitsite.com/foo/baz
$ANTIDOTE_HOME/fakegitsite.com/foo/qux
$ANTIDOTE_HOME/fakegitsite.com/getantidote/zsh-defer
$ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy
%
```

`antidote list -d` (short flag):

```zsh
% antidote list -d | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/fakegitsite.com/bar/baz
$ANTIDOTE_HOME/fakegitsite.com/foo/bar
$ANTIDOTE_HOME/fakegitsite.com/foo/baz
$ANTIDOTE_HOME/fakegitsite.com/foo/qux
$ANTIDOTE_HOME/fakegitsite.com/getantidote/zsh-defer
$ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy
%
```

### Long

`antidote list --long` shows key-value info per bundle:

```zsh
% antidote list --long | head -5
Repo:   bar/baz
Path:   $HOME/.cache/antidote/fakegitsite.com/bar/baz
URL:    https://fakegitsite.com/bar/baz
SHA:    1aa9550512f5606c5c23b11f5a9ad660d6c10fb4

%
```

`antidote list -l` (short flag):

```zsh
% antidote list -l | head -5
Repo:   bar/baz
Path:   $HOME/.cache/antidote/fakegitsite.com/bar/baz
URL:    https://fakegitsite.com/bar/baz
SHA:    1aa9550512f5606c5c23b11f5a9ad660d6c10fb4

%
```

SSH bundles show the full SSH URL:

```zsh
% antidote list --long | grep -A3 'Repo:.*foo/qux'
Repo:   git@fakegitsite.com:foo/qux
Path:   $HOME/.cache/antidote/fakegitsite.com/foo/qux
URL:    git@fakegitsite.com:foo/qux
SHA:    89661d7f95e6d805d4da6e1dc9bbaba9b126322a
%
```

Unpinned bundles don't show a Pinned line:

```zsh
% antidote list --long | grep -c 'Pinned:'
0
%
```

### JSONL

`antidote list --jsonl`

```zsh
% antidote list --jsonl | subenv ANTIDOTE_HOME
{"url":"https://fakegitsite.com/bar/baz","repo":"bar/baz","path":"$ANTIDOTE_HOME/fakegitsite.com/bar/baz","sha":"1aa9550512f5606c5c23b11f5a9ad660d6c10fb4"}
{"url":"https://fakegitsite.com/foo/bar","repo":"foo/bar","path":"$ANTIDOTE_HOME/fakegitsite.com/foo/bar","sha":"400b29a76d68fd7c40bc7c0460424ab089b1e68a"}
{"url":"https://fakegitsite.com/foo/baz","repo":"foo/baz","path":"$ANTIDOTE_HOME/fakegitsite.com/foo/baz","sha":"98cdde20c338bdb4df6efefd7f812d38ecc62b70"}
{"url":"git@fakegitsite.com:foo/qux","repo":"git@fakegitsite.com:foo/qux","path":"$ANTIDOTE_HOME/fakegitsite.com/foo/qux","sha":"89661d7f95e6d805d4da6e1dc9bbaba9b126322a"}
{"url":"https://fakegitsite.com/getantidote/zsh-defer","repo":"getantidote/zsh-defer","path":"$ANTIDOTE_HOME/fakegitsite.com/getantidote/zsh-defer","sha":"57ddc6fc6fba9862b899c483b6746b43c07dfb0d"}
{"url":"https://fakegitsite.com/ohmy/ohmy","repo":"ohmy/ohmy","path":"$ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy","sha":"1cc5b7ebe76328350234e841e72729f40057e2b6"}
%
```

`antidote list -j` (short flag):

```zsh
% antidote list -j | wc -l | awk '{print $1}'
6
%
```

Unpinned JSONL entries don't include a pin field:

```zsh
% antidote list --jsonl | grep -c '"pin"'
0
%
```

Use `jq` to extract repo and URL pairs:

```zsh
% antidote list --jsonl | jq -r '[.repo, .url] | @tsv' | sort | sed $'s/\t/    /g'
bar/baz    https://fakegitsite.com/bar/baz
foo/bar    https://fakegitsite.com/foo/bar
foo/baz    https://fakegitsite.com/foo/baz
getantidote/zsh-defer    https://fakegitsite.com/getantidote/zsh-defer
git@fakegitsite.com:foo/qux    git@fakegitsite.com:foo/qux
ohmy/ohmy    https://fakegitsite.com/ohmy/ohmy
%
```

Use `jq` to extract repo and directory pairs:

```zsh
% antidote list --jsonl | jq -r '[.repo, .path] | @tsv' | sort | subenv ANTIDOTE_HOME | sed $'s/\t/    /g'
bar/baz    $ANTIDOTE_HOME/fakegitsite.com/bar/baz
foo/bar    $ANTIDOTE_HOME/fakegitsite.com/foo/bar
foo/baz    $ANTIDOTE_HOME/fakegitsite.com/foo/baz
getantidote/zsh-defer    $ANTIDOTE_HOME/fakegitsite.com/getantidote/zsh-defer
git@fakegitsite.com:foo/qux    $ANTIDOTE_HOME/fakegitsite.com/foo/qux
ohmy/ohmy    $ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy
%
```

Use `jq` to extract repo and SHA pairs:

```zsh
% antidote list --jsonl | jq -r '[.repo, .sha[0:7]] | @tsv' | sort | sed $'s/\t/    /g'
bar/baz    1aa9550
foo/bar    400b29a
foo/baz    98cdde2
getantidote/zsh-defer    57ddc6f
git@fakegitsite.com:foo/qux    89661d7
ohmy/ohmy    1cc5b7e
%
```

## Teardown

```zsh
% t_teardown
%
```
