# fake foo/bar
echo "sourcing getantidote/zsh-defer..."
plugins=($plugins getantidote/zsh-defer)
function zsh-defer {
  $@
}
