# Changelog

Notable changes to this project will be documented in this file.

## [v2.1.0]

- Add `using:` directive for loading subplugins from monorepos and local paths (eg: oh-my-zsh, prezto).
- Improve error detection: invalid bundles and conflicting pin/branch annotations are now caught during parsing and reported with line numbers. Non-fatal errors skip the offending bundle but allow the rest to load. Fatal conflicts bail immediately.
- Ensure all non-script output from `antidote bundle` now begins with `#`, making redirected output safer to source. Exit code check is preferred for verifying bundle success.
- Add `zstyle ':antidote:home' dir ...` as an alternative to `$ANTIDOTE_HOME` to configure the antidote home directory for those who prefer to only use zstyles. If both are used, `$ANTIDOTE_HOME` wins.
- Refactor bundle parser to use an associative matrix, improving performance and enabling richer per-bundle metadata.

## [v2.0.12]

- Add syntax definition for antidote bundle files (`.zsh_plugins.txt`). See [misc/zsh_plugins.sublime-syntax](https://raw.githubusercontent.com/mattmc3/antidote/main/misc/zsh_plugins.sublime-syntax).
- Use bat for fzf snapshot preview when available, using our new syntax highlighter, with fallback to basic coloring if bat is unavailable or syntax is not installed
- Add `zstyle ':antidote:bat' opts ...` to allow user to configure their preferred bat options
- Fix `antidote update` to fail faster on git errors
- Add tests to ensure git autostashing is working

## [v2.0.11]

- Feature [#258](https://github.com/mattmc3/antidote/issues/258): fzf improvements

## [v2.0.10]

- Add `antidote snapshot home` subcommand to print the snapshot directory path
- Fix `antidote --version` printing a git error when installed outside a git repo (eg: Homebrew) ([#259](https://github.com/mattmc3/antidote/issues/259))

## [v2.0.9]

- Remove stray `setopt warn_create_global warn_nested_var` from testing

## [v2.0.8]

- Refactor for better performance

## [v2.0.7]

- Fix for [#255](https://github.com/mattmc3/antidote/issues/255): `antidote update` displayed the old version instead of the new version after self-update

## [v2.0.6]

- Fix `antidote snapshot` fzf picker regression in [#253](https://github.com/mattmc3/antidote/issues/253)
- Add `zstyle ':antidote:fzf' cmd ...` to configure which picker command is used for snapshot selection. Supports custom commands and paths to alternative `fzf` locations
- Allow disabling picker-based snapshot selection by setting `zstyle ':antidote:fzf' cmd ''`

## [v2.0.5]

- Fix `antidote list` empty-state detection to reliably warn when no bundles are found
- More fixes for [#247](https://github.com/mattmc3/antidote/issues/247)
- Fix bundle discovery to follow a symlinked `ANTIDOTE_HOME` path (`find -H`)
- Fix `antidote purge --all` for symlinked `ANTIDOTE_HOME` by clearing symlink contents before deleting the symlink path
- Add regression coverage for symlinked `ANTIDOTE_HOME` across `list`, `path`, `update`, `snapshot`, and `purge`
- Fix `antidote snapshot` commands launching fzf in non-interactive shells
- Fix test fixtures for git 2.17 compatibility
- Bump `actions/checkout` to v4

## [v2.0.4]

- Add `--diagnostics` flag to show antidote and system info for troubleshooting
- Add GitHub issue templates for bug reports and feature requests
- Fix `antidote list` silently exiting with error when no bundles are cloned ([#247](https://github.com/mattmc3/antidote/issues/247))
- Fix `antidote update` comparing short SHAs which could produce incorrect output (updates worked, but the output was potentially confusing for large repos)
- Refactor `antidote-dispatch` into separate autoloaded functions (`antidote-help`, `antidote-load`, `antidote-update`) to be more maintainable
- Clean up and alphabetize internal git helper functions

## [v2.0.3]

- Reuse existing clones when `path-style` changes, avoiding duplicate clones ([#245](https://github.com/mattmc3/antidote/issues/245))
- Remove legacy duplicate clones during bundling when multiple path-style directories exist
- Fix `find_bundles` failing when cloned bundles don't match the current `path-style`
- Fix `antidote bundle` emitting output before ensuring a successful clone operation
- `antidote list` now shows path and URL by default, and now has a `-u/--url` flag

## [v2.0.2]

- Minor fix for bump2version covering more files in the test suite

## [v2.0.1]

- Fix for gist cloning [#243](https://github.com/mattmc3/antidote/issues/243)

## [v2.0.0]

### Added

- New `antidote snapshot` command lets you save, restore, and list point-in-time snapshots of your plugin state
  - `antidote snapshot save` writes a snapshot file capturing the exact commit SHA of every cloned bundle
  - `antidote snapshot restore` restores your bundles to a previous state (uses the most recent snapshot if no file is given)
  - `antidote snapshot remove` removes snapshot files (interactive multi-select with `fzf` if available)
  - `antidote snapshot list` shows all available snapshots
- Snapshots are saved automatically during `antidote update` (static mode only)
- To disable automatic snapshotting during updates, set this zstyle in your config (eg: ~/.config/antidote/config.zsh):
  ```zsh
  zstyle ':antidote:snapshot:automatic' enabled no
  ```
- If `fzf` is installed, `antidote snapshot restore` gives you an interactive picker with a preview of each snapshot
- Snapshot storage location and rolling history limit are configurable via `zstyle`
- New `pin:` annotation lets you lock a bundle to a specific commit SHA (full 40-character SHA required)
  - Example: `zsh-users/zsh-autosuggestions pin:85919cd1ffa7d2d5412f6d3fe437ebdbeeec4fc5`
- Pinned bundles are skipped during `antidote update`
- `antidote update --dry-run` / `-n`: check for available updates without touching anything
- `antidote list` now shows URLs by default
- `antidote list --long` / `-l`: show verbose key-value info per bundle (repo, path, URL, SHA, pin status)
- `antidote list --dirs` / `-d`: show bundle directory paths
- `antidote list --jsonl` / `-j`: machine-readable JSONL output (includes pin status when pinned)
- antidote can now read an optional config `~/.config/antidote/config.zsh` on startup (respects `$XDG_CONFIG_HOME`)
- A template config file is included showing all available zstyles (see `templates/config.zsh`)
- New `path-style` zstyle controls how bundle directories are named on disk:
  - `full` (default): `$ANTIDOTE_HOME/github.com/owner/repo`
  - `short`: `$ANTIDOTE_HOME/owner/repo`
  - `escaped`: `$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-owner-SLASH-repo` (legacy antibody style)
  ```zsh
  zstyle ':antidote:bundle' path-style short
  ```
- New git zstyles let you clone from non-GitHub hosts or default to SSH for clones:
  ```zsh
  zstyle ':antidote:git' site gitlab.com
  zstyle ':antidote:git' protocol ssh
  ```
- Interactive selection uses `fzf` when available
- Color output now respects `NO_COLOR`, `CLICOLOR_FORCE`, and terminal capabilities
- Dockerfiles included for reproducible test environments
- Tons of new unit tests to verify correctness and provide stability

### Changed

- The codebase has been consolidated from many small functions into a single self-contained `antidote.zsh`
- Internal dispatching has been rewritten and streamlined
- `antidote list` flags have been redesigned and many removed and replaced by `--long`, `--dirs`, and `--jsonl`

### Removed

- Antibody compatibility mode has been removed
- `antidote list` old flags (`--short`, `--short-name`, `--url`, `--sha`, `--short-sha`, `--pinned`) have been removed in favor of `--long`

### Notes

- Pin any repos you want to keep on a certain release. They will be skipped when running `antidote update`. Use `antidote list --long` to see current SHAs, then add `pin:<SHA>` annotations to your .zsh_plugins.txt.
