0=${(%):-%N}
@echo "=== ${0:t:r} ==="

source ${0:a:h}/includes/setup_teardown.zsh
setup

pz help > /dev/null 2>&1
@test '`pz help` command succeeds' $? -eq 0
pzhelp=("${(@f)$(pz help)}")

@test 'count of help lines is 14' ${#pzhelp[@]} -eq 14
[[ ${pzhelp[1]} = "pz - "* ]]
@test '`pz help` gives us a tagline' $? -eq 0
@test '`pz help` tells us usage' ${pzhelp[3]} = "usage:"
@test '`pz help` gives us the commands it uses' ${pzhelp[6]} = "commands:"

# extended help
pz help list > /dev/null 2>&1
@test '`pz help list` extended help command succeeds' $? -eq 0
pzhelplist=("${(@f)$(pz help list)}")
@test 'count of help lines is 5' ${#pzhelplist[@]} -eq 5
@test '`pz help list` tells us usage' "${pzhelplist[1]}" = "usage:"
@test '`pz help list` tells us flags' "${pzhelplist[4]}" = "flags:"

# extended help invalid
pz help invalid > /dev/null 2>&1
@test '`pz help invalid` extended help command fails' $? -ne 0
pzhelpinvalid=("${(@f)$(pz help invalid)}")
[[ ${pzhelpinvalid[1]} = "No extended help available for command:"* ]]
@test '`pz help invalid` gives a nice message' $? -eq 0

teardown
unset pzhelp pzhelplist pzhelpinvalid
