# autoload test functions
fpath+=( $PWD/tests/functions )
autoload -Uz $fpath[-1]/*(N.:t)
t_setup
