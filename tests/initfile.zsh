0=${(%):-%N}
@echo "=== ${0:t:r} ==="

source ${0:a:h}/includes/setup_teardown.zsh
setup "fakes"

initfile=$(pz initfile zsh-incompletions)
@test "pz initfile zsh-incompletions" $initfile = $PZ_PLUGIN_HOME/zsh-incompletions/zsh-incompletions.plugin.zsh

initfile=$(pz initfile fakemyzsh)
@test "pz initfile fakemyzsh" $initfile = $PZ_PLUGIN_HOME/fakemyzsh/fake-my-zsh.sh

initfile=$(pz initfile fakemyzsh lib/one.zsh)
@test "pz initfile fakemyzsh lib/one.zsh" $initfile = $PZ_PLUGIN_HOME/fakemyzsh/lib/one.zsh

initfile=$(pz initfile fakemyzsh lib/two)
@test "pz initfile fakemyzsh lib/two" $initfile = $PZ_PLUGIN_HOME/fakemyzsh/lib/two.zsh

initfile=$(pz initfile fakemyzsh plugins/foobar)
@test "pz initfile fakemyzsh plugins/foobar" $initfile = $PZ_PLUGIN_HOME/fakemyzsh/plugins/foobar/foobar.plugin.zsh

initfile=$(pz initfile fakemyzsh themes/russellbobby)
@test "pz initfile fakemyzsh themes/russellbobby" $initfile = $PZ_PLUGIN_HOME/fakemyzsh/themes/russellbobby.zsh-theme

initfile=$(pz initfile preztno modules/soarin)
@test "pz initfile preztno modules/soarin" $initfile = $PZ_PLUGIN_HOME/preztno/modules/soarin/init.zsh

initfile=$(pz initfile upper.zsh)
@test "pz initfile upper.zsh" $initfile = $PZ_PLUGIN_HOME/upper.zsh/upper.plugin.zsh

initfile=$(pz initfile zee)
@test "pz initfile zee" $initfile = $PZ_PLUGIN_HOME/zee/zee.sh

initfile=$(pz initfile notaplugin)
@test "pz initfile notaplugin fails" $? -ne 0
@test "pz initfile notaplugin" $initfile = ''

teardown
