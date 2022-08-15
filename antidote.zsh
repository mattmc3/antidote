0=${(%):-%x}
fpath+=${0:A:h}/functions
export MANPATH="$MANPATH:${0:A:h}/man"

# setup the environment
for _fn in ${0:A:h}/functions/*; do
  (( $+functions[${_fn:t}] )) && unfunction ${_fn:t}
  autoload -Uz "${_fn}"
done
unset _fn

# setup completions
_antidote() {
	IFS=' ' read -A reply <<< "help bundle update home purge list load path init install"
}
compctl -K _antidote antidote
