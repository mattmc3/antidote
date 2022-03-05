0=${(%):-%x}}
for _fn in ${0:A:h}/functions/*; do
  unfunction ${_fn:t} &> /dev/null
  autoload -Uz $_fn
done
unset _fn
