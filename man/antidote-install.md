---
title: antidote-install
section: 1
header: Antidote Manual
---

# NAME

**antidote install** - install a bundle

# SYNOPSIS

| antidote install [-h|\--help] [-k|\--kind \<kind\>] [-p|\--path \<path\>]
|                  [-a|\--autoload \<path\>] [-c|\--conditional \<func\>]
|                  [\--pre \<func\>] [\--post \<func\>]
|                  [-b|\--branch \<branch\>] \<bundle\> [\<bundlefile\>]

# DESCRIPTION

**antidote-install** clones a new bundle and adds it to your plugins file.

The default bundle file is **${ZDOTDIR:-\$HOME}/.zsh_plugins.txt**. This can be overridden with the following **zstyle**:

|   zstyle \':antidote:bundle\' file /path/to/my/bundle_file.txt

# OPTIONS

-h, \--help
:   Show the help documentation.

-k, \--kind <kind>
:   The kind of bundle. Valid values: autoload, fpath, path, clone, defer, zsh.

-p, \--path <path>
:   A relative subpath within the bundle where the plugin is located.

-b, \--branch <path>
:   The git branch to use.

-a, \--autoload <path>
:   A relative subpath within the bundle where autoload function files are located.

-c, \--conditional <func>
:   A conditional function used to check whether to load the bundle.

\--pre <func>
:   A function to be called prior to loading the bundle.

\--post <func>
:   A function to be called after loading the bundle.

\<bundle\>
:   Bundle to be installed.

[\<bundlefile\>]
:   Bundle file to write to if not using the default. Defaults to **${ZDOTDIR:-\$HOME}/.zsh_plugins.txt** or zstyle setting.

# EXAMPLES

|   antidote install zsh-users/zsh-history-substring-search
