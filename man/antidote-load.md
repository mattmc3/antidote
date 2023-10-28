---
title: antidote-load
section: 1
header: Antidote Manual
---

# NAME

**antidote load** - statically source bundles

# SYNOPSIS

| antidote load [\<bundlefile\> [\<staticfile\>]]

# DESCRIPTION

**antidote-load** will turn the bundle file into a static load file and then source it.

The default bundle file is **${ZDOTDIR:-\$HOME}/.zsh_plugins.txt**. This can be overridden with the following **zstyle**:

|   zstyle \':antidote:bundle\' file /path/to/my/bundle_file.txt

The default static file is **${ZDOTDIR:-\$HOME}/.zsh_plugins.zsh**. This can be overridden with the following **zstyle**:

|   zstyle \':antidote:static\' file /path/to/my/static_file.zsh

# OPTIONS

-h, \--help
:   Show the help documentation.

[\<bundlefile\>]
:   The plugins file to source if not using the default. Defaults to **${ZDOTDIR:-\$HOME}/.zsh_plugins.txt** or zstyle setting.

[\<staticfile\>]
:   The static plugins file to generate if not using the default. Defaults to **${ZDOTDIR:-\$HOME}/.zsh_plugins.zsh** or zstyle setting.
