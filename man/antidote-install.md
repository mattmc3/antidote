---
title: antidote-install
section: 1
header: Antidote Manual
---

# NAME

**antidote install** - install a bundle

# SYNOPSIS

| antidote install [-h|--help] [-k|--kind <kind>] [-p|--path <path>]
|                  [-b|--branch <branch>] <bundle> [<bundlefile>]

# DESCRIPTION

**antidote-install** clones a new bundle and adds it to your plugins file.

# OPTIONS

-h, \--help
:   Show the help documentation.

-k, \--kind <kind>
:   The kind of bundle. Valid values: fpath, path, clone, defer, zsh.

-p, \--path <path>
:   A relative subpath within the bundle where the plugin is located.

-b, \--branch <path>
:   The git branch to use.

\<bundle\>
:   Bundle to be installed.

[\<bundlefile\>]
:   Bundle file to write to if not using the default. Defaults to **${ZDOTDIR:-~}/.zsh_plugins.txt** or zstyle setting.

# EXAMPLES

|   antidote install zsh-users/zsh-history-substring-search
