# fake foo/bar
echo "sourcing romkatv/zsh-defer..."
plugins=($plugins romkatv/zsh-defer)
function zsh-defer {
  $@
}
