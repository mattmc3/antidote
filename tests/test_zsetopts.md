# antidote respects setopts

## Setup

```zsh
% source ./tests/_setup.zsh
% source ./antidote.zsh
%
```

Set up a plugin that changes Zsh options
```zsh
% plugin_file=$ZDOTDIR/antidote_home/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar/bar.plugin.zsh
% mkdir -p $plugin_file:h && touch $plugin_file
% echo "unsetopt noaliases" >>$plugin_file
% echo "setopt autocd" >>$plugin_file
% echo "foo/bar" >$ZDOTDIR/.zsh_plugins.txt
%
```

## Test that plugins that run setopts work

Verify initial state
```zsh
% setopt noaliases
% set -o | grep noaliases
noaliases             on
% set -o | grep autocd
autocd                off
%
```

Load the plugins and see if the option took
```zsh
% antidote load &>/dev/null  #=> --exit 0
% set -o | grep noaliases
noaliases             off
% set -o | grep autocd
autocd                on
% # cleanup
% setopt noaliases no_autocd
%
```

Tests to ensure [#86](https://github.com/mattmc3/antidote/issues/86) stays fixed.
Check that stderr is empty.
```zsh
% setopt posix_identifiers
% antidote -v 3>&1 2>&3 >/dev/null #=> --exit 0

% antidote -h 3>&1 2>&3 >/dev/null #=> --exit 0

% antidote help 3>&1 2>&3 >/dev/null #=> --exit 0

% # cleanup
% unsetopt posix_identifiers
%
```

## Clark Grizwold lighting ceremony!

<iframe src="https://giphy.com/embed/gB9wIPXav2Ryg" width="480" height="270" frameBorder="0" class="giphy-embed" allowFullScreen></iframe><p><a href="https://giphy.com/gifs/comedy-retro-christmas-lights-gB9wIPXav2Ryg">via GIPHY</a></p>

```zsh
% optcnt=$(setopt | wc -l | tr -d ' ')
% echo $optcnt  #=> --regex ^\d+$
% test $optcnt -lt 10 && echo "less than 10 enabled zsh opts"
less than 10 enabled zsh opts
% # now lets turn on all the lights
% echo '$ZDOTDIR/custom/plugins/grizwold' >$ZDOTDIR/.zsh_plugins.txt
% antidote load
% optcnt=$(setopt | wc -l | tr -d ' ')
% test $optcnt -gt 150 && echo "zillions of enabled zsh options (>150)"
zillions of enabled zsh options (>150)
%
```

## Teardown

```zsh
% unsetopt $grizwold_zopts
% t_teardown
%
```
