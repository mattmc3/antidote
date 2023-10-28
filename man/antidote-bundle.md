---
title: antidote-bundle
section: 1
header: Antidote Manual
---

# NAME

**antidote bundle** - download a bundle and print its source line

# SYNOPSIS

| antidote bundle [\<bundles\>...]

# DESCRIPTION

**antidote-bundle** assembles your Zsh plugins. Bundles can be git repos, or local files or directories. If a plugin is a repo, it will be cloned if necessary. The zsh code necessary to load (source) the plugin is then printed.

|   antidote bundle gituser/gitrepo
|   antidote bundle $ZSH_CUSTOM/plugins/myplugin
|   antidote bundle ${ZDOTDIR:-\$HOME}/.zlibs/myfile.zsh

Bundles also support annotations. Annotations allow you have finer grained control over your plugins. Annotations are used in the form \'keyword:value\'.

`kind`
:   - **zsh**: A zsh plugin. This is the default kind of bundle.
:   - **fpath**: Only add the plugin to your _\$fpath_.
:   - **path**: Add the plugin to your _\$PATH_.
:   - **clone**: Only clone a plugin, but don't do anything else with it.
:   - **defer**: Defers loading of a plugin using \'romkatv/zsh-defer\'.
:   - **autoload**: Autoload all the files in the plugin directory as zsh functions.

`branch`
:   The branch annotation allows you to change the default branch of a plugin's repo from **main** to a branch of your choosing.

`path`
:   The path annotation allows you to use a subdirectory or file within a plugin's structure instead of the root plugin (eg: \'path:plugins/subplugin\').

`conditional`
:   The conditonal annotation allows you to wrap an **if** statement around a plugin's load script. Supply the name of a zero argument zsh function to conditional to perform the test (eg: \'conditional:is-macos\').

`pre` / `post`
:   The pre and post annotations allow you to call a function before or after a plugin's load script. This is helpful when configuring plugins, since the configuration functions will only run for active plugins. Supply the name of a zero argument zsh function to pre or post.

`autoload`
:   The autoload annotation allows you to autoload a zsh functions directory in addition to however the plugin was loaded as specified by \'kind\'. Supply a relative path to autoload (eg: \'autoload:functions\').

Cloned repo directory names can be overridden with the following **zstyle**:

|   zstyle \':antidote:bundle\' use-friendly-names \'yes\'

# OPTIONS

-h, \--help
:   Show the help documentation.

[*\<bundles\>...*]
:   Zsh plugin bundles

# EXAMPLES

Using the **kind:** annotation...

|   # a regular plugin (kind:zsh is implied, so it's unnecessary)
|   antidote bundle zsh-users/zsh-history-substring-search kind:zsh

|   # add prompt plugins to $fpath
|   antidote bundle sindresorhus/pure kind:fpath

|   # add utility plugins to $PATH
|   antidote bundle romkatv/zsh-bench kind:path

|   # clone a repo for use in other ways
|   antidote bundle mbadolato/iTerm2-Color-Schemes kind:clone

|   # autoload a functions directory
|   antidote bundle sorin-ionescu/prezto path:modules/utility/functions kind:autoload

|   # defer a plugin to speed up load times
|   antidote bundle olets/zsh-abbr kind:defer

Using the **branch:** annotation...

|   # don't use the main branch, use develop instead
|   antidote bundle zsh-users/zsh-autosuggestions branch:develop

Using the **path:** annotation...

|   # load oh-my-zsh
|   antidote bundle ohmyzsh/ohmyzsh path:lib
|   antidote bundle ohmyzsh/ohmyzsh path:plugins/git

Using the **conditional:** annotation...

|   # define a conditional function prior to loading antidote
|   function is_macos {
|     [[ $OSTYPE == darwin* ]] || return 1
|   }
|
|   # conditionally load a plugin using the function you made
|   antidote bundle ohmyzsh/ohmyzsh path:plugins/macos conditional:is_macos

