# autoload test functions
0=${(%):-%N}
autoload -U ${0:A:h}/functions/t_setup
t_setup
