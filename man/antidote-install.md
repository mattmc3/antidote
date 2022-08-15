---
title: antidote-install
section: 1
header: Antidote Manual
---

# NAME

**antidote install** - install a bundle

# SYNOPSIS

| antidote install <bundle> [<bundlefile>]

# DESCRIPTION

**antidote-install** clones a new bundle and adds it to your plugins file.

# OPTIONS

-h, \--help
:   Show the help documentation.

\<bundle\>
:   Bundle to be installed.

[\<bundlefile\>]
:   Bundle file to write to if not using the default. Defaults to **${ZDOTDIR:-~}/.zsh_plugins.txt** or zstyle setting.

# EXAMPLES

|   antidote install zsh-users/zsh-history-substring-search
