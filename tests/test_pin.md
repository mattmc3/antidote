# antidote pin annotation tests

## Setup

```zsh
% source ./tests/__init__.zsh
% t_setup
% antidote bundle <$ZDOTDIR/.base_test_fixtures.txt &>/dev/null
%
```

## Pin annotation

### Clone with pin

Cloning a bundle with `pin:` should clone at the pinned ref.

```zsh
% antidote bundle 'pintest/pinme pin:v1.0.0' >/dev/null
# antidote cloning pintest/pinme...
%
```

Verify the repo is in detached HEAD state at the pinned ref.

```zsh
% bundledir=$ANTIDOTE_HOME/fakegitsite.com/pintest/pinme
% git -C $bundledir rev-parse --abbrev-ref HEAD
HEAD
%
```

Verify git config has the pin stored.

```zsh
% git -C $bundledir config --get antidote.pin
v1.0.0
%
```

### Pin produces correct script output

The pinned bundle should still generate the correct source script.

```zsh
% antidote __private__ zsh_script --pin v1.0.0 pintest/pinme | subenv ANTIDOTE_HOME
fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/pintest/pinme" )
source "$ANTIDOTE_HOME/fakegitsite.com/pintest/pinme/pinme.plugin.zsh"
%
```

### Update skips pinned bundles

```zsh
% zstyle ':antidote:test:version' show-sha off
% zstyle ':antidote:test:git' autostash off
% antidote update --bundles 2>&1 | grep pintest
antidote: skipping update for pinned bundle: pintest/pinme (at v1.0.0)
%
```

### Removing pin clears git config

When a bundle is re-bundled without `pin:`, the git config should be cleared
so that `antidote update` will no longer skip it.

```zsh
% antidote bundle 'pintest/pinme' >/dev/null
% git -C $bundledir config --get antidote.pin  #=> --exit 1
%
```

### Adding pin to an already-cloned unpinned bundle

The bundle was unpinned above. Re-bundling with a pin should checkout the pinned
ref and set the git config.

```zsh
% antidote bundle 'pintest/pinme pin:v1.0.0' >/dev/null
% git -C $bundledir config --get antidote.pin
v1.0.0
% git -C $bundledir rev-parse --abbrev-ref HEAD
HEAD
%
```

### Changing pin ref on existing bundle

Changing the pin from v1.0.0 to v1.1.0 should checkout the new ref.

```zsh
% antidote bundle 'pintest/pinme pin:v1.1.0' >/dev/null
% git -C $bundledir config --get antidote.pin
v1.1.0
%
```

### Pin with invalid ref fails

Cloning a bundle with an invalid pin ref should fail. Remove the previously cloned
bundle first so it tries to clone fresh.

```zsh
% rm -rf $ANTIDOTE_HOME/fakegitsite.com/pintest/pinme
% antidote __private__ zsh_script --kind clone --pin v99.0.0 pintest/pinme 2>&1 | tail -1
antidote: error: pin ref 'v99.0.0' not found for pintest/pinme
%
```

### Conflict detection

Test `bundle_check_conflicts` directly.

Conflicting pins should fail.

```zsh
% printf 'pintest/pinme pin:v1.0.0\npintest/pinme pin:v1.1.0\n' | antidote __private__ bundle_check_conflicts 2>&1
antidote: error: conflicting pin for 'pintest/pinme': pin:v1.1.0 vs pin:v1.0.0
%
```

Conflicting branches should fail.

```zsh
% printf 'foo/bar branch:main\nfoo/bar branch:dev\n' | antidote __private__ bundle_check_conflicts 2>&1
antidote: error: conflicting branch for 'foo/bar': branch:dev vs branch:main
%
```

Mixed pin/no-pin for the same repo should fail.

```zsh
% printf 'pintest/pinme pin:v1.0.0\npintest/pinme path:lib\n' | antidote __private__ bundle_check_conflicts 2>&1
antidote: error: inconsistent pin for 'pintest/pinme': some entries have pin:v1.0.0, others do not
%
```

Mixed branch/no-branch for the same repo should fail.

```zsh
% printf 'foo/bar branch:dev\nfoo/bar path:lib\n' | antidote __private__ bundle_check_conflicts 2>&1
antidote: error: inconsistent branch for 'foo/bar': some entries have branch:dev, others do not
%
```

Identical pins for the same repo should be fine.

```zsh
% printf 'pintest/pinme pin:v1.0.0\npintest/pinme pin:v1.0.0 path:lib\n' | antidote __private__ bundle_check_conflicts  #=> --exit 0
%
```

Different repos with different pins should be fine.

```zsh
% printf 'foo/bar pin:v1.0.0\npintest/pinme pin:v2.0.0\n' | antidote __private__ bundle_check_conflicts  #=> --exit 0
%
```

Bundling with conflicting pins should also fail end-to-end.

```zsh
% printf 'pintest/pinme pin:v1.0.0 path:lib\npintest/pinme pin:v1.1.0 path:other\n' | antidote bundle 2>&1 | tail -1
antidote: error: conflicting pin for 'pintest/pinme': pin:v1.1.0 vs pin:v1.0.0
%
```

## Teardown

```zsh
% t_teardown
%
```
