
@echo "=== list ==="

0=${(%):-%N}
source ${0:a:h}/includes/setup_teardown.zsh

setup "fakes"

# IFS=$'\n'
pzlist=($(pz list))

@test 'count of listing fake plugins is 6' ${#pzlist[@]} -eq 6
@test '1st fake plugin is fake-my-zsh' $pzlist[1] = 'fakemyzsh'
@test '2nd fake plugin is notaplugin' $pzlist[2] = 'notaplugin'
@test '3rd fake plugin is preztno' $pzlist[3] = 'preztno'
@test '4th fake plugin is upper.zsh' $pzlist[4] = 'upper.zsh'
@test '5th fake plugin is zee' $pzlist[5] = 'zee'
@test '6th fake plugin is zsh-incompletions' $pzlist[6] = 'zsh-incompletions'

# detailed list
pz list -d > /dev/null 2>&1
@test 'pz list -d succeeds' $? -eq 0

pzlistd=($(pz list -d))
@test 'count of detailed listing fake plugins is 6' ${#pzlistd[@]} -eq 6
@test 'first fake detailed plugin is fake-my-zsh' $pzlistd[1] = 'fakemyzsh'
@test 'last fake plugin is zsh-incompletions' $pzlistd[-1] = 'zsh-incompletions'

teardown
unset pzlist pzlistd
