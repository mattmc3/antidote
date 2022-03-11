# antidote

<a title="GetAntidote"
   href="https://getantidote.github.io"
   align="right">
<img align="right"
     height="80"
     alt="GetAntidote Logo"
     src="https://avatars.githubusercontent.com/u/101279220?s=80&v=4">
</a>

> Get the cure - Zsh plugin management made awesome</blockquote>
  
Antidote is a feature complete Zsh implementation of the legacy [Antibody][antibody]
plugin manager.

## Documentation

Documentation can be found at https://getantidote.github.io

## Installation

### Recommended install

To get the best performance and a seamless install of antidote, the recommended method
would be to add the following snippet to your `.zshrc`:

```zsh
# clone antidote if necessary and generate a static plugin file
zhome=${ZDOTDIR:-$HOME}
if [[ ! $zhome/.zsh_plugins.zsh -nt $zhome/.zsh_plugins.txt ]]; then
  [[ -e $zhome/.antidote ]]        || git clone --depth=1 https://github.com/mattmc3/antidote.git $zhome/.antidote
  [[ -e $zhome/.zsh_plugins.txt ]] || touch $zhome/.zsh_plugins.txt
  (
    source $zhome/.antidote/antidote.zsh
    antidote bundle <$zhome/.zsh_plugins.txt >$zhome/.zsh_plugins.zsh
  )
fi
autoload -Uz $zhome/.antidote/functions/antidote
source $zhome/.zsh_plugins.zsh
unset zhome
```

### Manual install
<details>
  <summary>Static plugins</summary>

  If you prefer an entirely manual installation with as little as possible in your
  `.zshrc`, you could always `git clone` antidote and `source` it yourself:

  ```zsh
  git clone --depth=1 https://github.com/mattmc3/antidote.git ${ZDOTDIR:-~}/.antidote
  source ${ZDOTDIR:-~}/.antidote/antidote.zsh
  ```

  Then create a `.zsh_plugins.txt` file with some plugins in it:

  ```zsh
  echo "zsh-users/zsh-syntax-highlighting"  >| ${ZDOTDIR:-~}/.zsh_plugins.txt
  echo "zsh-users/zsh-autosuggestions"     >>| ${ZDOTDIR:-~}/.zsh_plugins.txt
  ```

  Then generate your static plugins zsh file:

  ```zsh
  antidote bundle <${ZDOTDIR:-~}/.zsh_plugins.txt >${ZDOTDIR:-~}/.zsh_plugins.zsh
  ```

  Then source your static plugins files from your `.zshrc`:

  ```zsh
  # .zshrc
  source ${ZDOTDIR:-~}/.zsh_plugins.zsh
  ```

  You will need to manually regenerate your `.zsh_plugins.zsh` yourself every time you
  change your plugins.
</details>

<details>
  <summary>Dynamic plugins</summary>

  **Note:** _This installation method is provided for legacy purposes only, and is not
  recommended._

  Clone antidote:

  ```zsh
  git clone --depth=1 https://github.com/mattmc3/antidote.git ${ZDOTDIR:-~}/.antidote
  ```

  Add the following snippet to your `.zshrc`

  ```zsh
  # zshrc

  # initialize antidote for dynamic plugins
  source ${ZDOTDIR:-~}/.antidote/antidote.zsh
  source <(antidote init)

  # bundle plugins individually
  antidote bundle zsh-users/zsh-syntax-highlighting
  antidote bundle zsh-users/zsh-autosuggestions

  # or bundle using a plugins file
  antidote bundle <${ZDOTDIR:-~}/.zsh_plugins.txt
  ```
</details>

## Benchmarks

You can see how antidote compares with other setups [here][benchmarks].

## Plugin authors

If you authored a Zsh plugin, the recommended antidote snippet to tell your users how to
install your plugin would be this:

```zsh
antidote install gh_user/gh_repo
```

You can also do it more explicitly this way:

```zsh
echo gh_user/gh_repo >>|${ZDOTDIR:~}/.zsh_plugins.txt
```

## Credits

A big thank you to [Carlos](https://twitter.com/caarlos0) for all his work on
[antibody] over the years.

[antibody]:       https://getantibody.github.io
[benchmarks]:     https://github.com/romkatv/zsh-bench/blob/master/doc/linux-desktop.md
