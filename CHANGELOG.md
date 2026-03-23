# Changelog

Notable changes to this project will be documented in this file.

## [v2.0.0] - Unreleased

### Added

- New `antidote snapshot` command lets you save, restore, and list point-in-time snapshots of your plugin state
  - `antidote snapshot save` writes a snapshot file capturing the exact commit SHA of every cloned bundle
  - `antidote snapshot restore` restores your bundles to a previous state (uses the most recent snapshot if no file is given)
  - `antidote snapshot list` shows all available snapshots
- Snapshots are saved automatically during `antidote update` (static mode only)
- To disable automatic snapshotting during updates, set this zstyle in your config (eg: ~/.config/antidote/config.zsh):
  ```zsh
  zstyle ':antidote:snapshot:automatic' enabled no
  ```
- If `fzf` is installed, `antidote snapshot restore` gives you an interactive picker with a preview of each snapshot
- Snapshot storage location and rolling history limit are configurable via `zstyle`
- New `pin:` annotation lets you lock a bundle to a specific git ref (commit SHA recommended)
  - Example: `zsh-users/zsh-autosuggestions pin:3b1f2a4`
- Pinned bundles are skipped during `antidote update` and are recorded as commit SHAs in the lockfile
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

- Pin any repos you want to keep on a certain release. They will be skipped when running `antidote update`. Use `antidote list --detail` to see current SHAs, then add `pin:{{SHA}}` annotations to your .zsh_plugins.txt.
