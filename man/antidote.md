---
title: antidote
section: 1
header: Antidote Manual
---

# NAME

**antidote** - the cure to slow zsh plugin management

# SYNOPSIS

| antidote [-v | --version] [-h | --help] \<command\> [\<args\> ...]

# DESCRIPTION

**antidote** is a Zsh plugin manager made from the ground up thinking about performance.

It is fast because it can do things concurrently, and generates an ultra-fast static plugin file that you can easily load from your Zsh config.

It is written natively in Zsh, is well tested, and picks up where Antigen and Antibody left off.

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

# EXAMPLES

## A Simple Config

Create a _.zsh_plugins.txt_ file with a list of the plugins you want:

|    # ${ZDOTDIR:-\$HOME}/.zsh_plugins.txt
|    zsh-users/zsh-syntax-highlighting
|    zsh-users/zsh-history-substring-search
|    zsh-users/zsh-autosuggestions

Now, simply load your newly created static plugins file in your _.zshrc_.

|    # ${ZDOTDIR:-\$HOME}/.zshrc
|    source /path/to/antidote/antidote.zsh
|    antidote load

## A More Advanced Config

Your _.zsh_plugins.txt_ file supports annotations. Annotations tell antidote how to do things like load plugins from alternate paths. This lets you use plugins from popular frameworks like Oh-My-Zsh:

|    # ${ZDOTDIR:-\$HOME}/.zsh_plugins.txt
|    ohmyzsh/ohmyzsh path:lib
|    ohmyzsh/ohmyzsh path:plugins/git
|    ohmyzsh/ohmyzsh path:plugins/magic-enter
|    etc...

## Dynamic Bundling

Users familiar with legacy plugin managers like Antigen might prefer to use dynamic bundling. With dynamic bundling you sacrifice some performance to avoid having separate plugin files. To use dynamic bundling, we need to change how **antidote bundle** handles your plugins. We do this by sourcing the output from **antidote init**.

An example config might look like this:

|    source /path/to/antidote/antidote.zsh
|    source <(antidote init)
|    antidote bundle zsh-users/zsh-autosuggestions
|    antidote bundle ohmyzsh/ohmyzsh path:lib
|    antidote bundle ohmyzsh/ohmyzsh path:plugins/git

Instead of calling **antidote bundle** over and over, you might prefer to load bundles with a HEREDOC.

|    source /path/to/antidote/antidote.zsh
|    source <(antidote init)
|    antidote bundle <<EOBUNDLES
|        zsh-users/zsh-syntax-highlighting         # regular plugins
|        ohmyzsh/ohmyzsh path:lib                  # directories
|        ohmyzsh/ohmyzsh path:plugins/magic-enter  # frameworks
|        https://github.com/zsh-users/zsh-history-substring-search  # URLs
|    EOBUNDLES

## Installation

To install antidote you can clone it with git:

|   git clone --depth=1 https://github.com/mattmc3/antidote.git ${ZDOTDIR:-\$HOME}/.antidote

Then, simply add the following snippet to your .zshrc:

|   source ${ZDOTDIR:-\$HOME}/.antidote/antidote.zsh
|   antidote load

# CUSTOMIZATION

The location where antidote clones repositories can bu customized by setting **$ANTIDOTE_HOME**:

|   ANTIDOTE_HOME=/path/to/my/repos

The bundle directory in ANTIDOTE_HOME can be changed to use friendly names with the following **zstyle**:

|   zstyle \':antidote:bundle\' use-friendly-names on

The default bundle file is **${ZDOTDIR:-\$HOME}/.zsh_plugins.txt**. This can be overridden with the following **zstyle**:

|   zstyle \':antidote:bundle\' file /path/to/my/bundle_file.txt

The default static file is **${ZDOTDIR:-\$HOME}/.zsh_plugins.zsh**. This can be overridden with the following **zstyle**:

|   zstyle \':antidote:static\' file /path/to/my/static_file.zsh

The default options used by romkatv/zsh-defer can be changed with the following **zstyle**:

|   zstyle ':antidote:bundle:*' defer-options '-a'
|   zstyle ':antidote:bundle:foo/bar' defer-options '-p'

Bundles can be Zsh compiled with the following **zstyle**:

|   zstyle ':antidote:bundle:*' zcompile 'yes'

Or, if you only want to zcompile specific bundles, you can set those individually:

|   zstyle ':antidote:bundle:*' zcompile 'yes'
|   zstyle ':antidote:bundle:zsh-users/zsh-syntax-highlighting' zcompile 'no'

The static file can be Zsh compiled with the following **zstyle**:

|   zstyle ':antidote:static' zcompile 'yes'

# SEE ALSO

For more information, visit https://getantidote.github.io/
