---
title: antidote
section: 1
header: Antidote Manual
---

# NAME

**antidote** - the cure to slow zsh plugin management

# SYNOPSIS

| antidote [-v | --version] [-h | --help] <command> [<args> ...]

# DESCRIPTION

**antidote** is used to manage zsh plugins.

To install antidote, first you must clone it with git from an interactive zsh session:

    git clone --depth=1 https://github.com/mattmc3/antidote.git ${ZDOTDIR:-~}/.antidote

Then, simply add the following snippet to your .zshrc:

    source ${ZDOTDIR:-~}/.antidote/antidote.zsh
    antidote load

For more information, visit https://getantidote.github.io/

# OPTIONS

-h, \--help
:   Show context-sensitive help for antidote.

-v, \--version
:   Show currently installed antidote version.

# COMMANDS

`help`
:   Show documentation

`load`
:   Statically source all bundles from the plugins file

`bundle`
:   Clone bundle(s) and generate the static load script

`install`
:   Clone a new bundle and add it to your plugins file

`update`
:   Update antidote and its cloned bundles

`purge`
:   Remove a cloned bundle

`home`
:   Print where antidote is cloning bundles

`list`
:   List cloned bundles

`path`
:   Print the path of a cloned bundle

`init`
:   Initialize the shell for dynamic bundles
