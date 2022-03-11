0=${(%):-%x}
for _fn in ${0:A:h}/functions/*; do
  unfunction ${_fn:t} &> /dev/null
  autoload -Uz $_fn
done
unset _fn

_antidote() {
	IFS=' ' read -A reply <<< "help bundle update home purge list load path init install"
}
compctl -K _antidote antidote
