
@echo "=== zcompile ==="

0=${(%):-%N}
source ${0:a:h}/includes/setup_teardown.zsh

setup "fakes"

@test "zsh-incompletions.plugin.zsh is not compiled" ! -f $PZ_PLUGIN_HOME/zsh-incompletions/zsh-incompletions.plugin.zsh.zwc
@test "fakemyzsh/lib/one is not compiled" ! -f $PZ_PLUGIN_HOME/fakemyzsh/lib/one.zsh.zwc
@test "fakemyzsh/themes/russellbobby is not compiled" ! -f $PZ_PLUGIN_HOME/fakemyzsh/themes/russellbobby.zsh-theme.zwc
@test "preztno/modules/soarin is not compiled" ! -f $PZ_PLUGIN_HOME/preztno/modules/soarin/init.zsh.zwc

# zcompile
pz zcompile > /dev/null 2>&1
@test 'pz zcompile succeeds' $? -eq 0

@test "zsh-incompletions.plugin.zsh is compiled" -f $PZ_PLUGIN_HOME/zsh-incompletions/zsh-incompletions.plugin.zsh.zwc
@test "fakemyzsh/lib/one is compiled" -f $PZ_PLUGIN_HOME/fakemyzsh/lib/one.zsh.zwc
@test "fakemyzsh/themes/russellbobby is compiled" -f $PZ_PLUGIN_HOME/fakemyzsh/themes/russellbobby.zsh-theme.zwc
@test "preztno/modules/soarin is compiled" -f $PZ_PLUGIN_HOME/preztno/modules/soarin/init.zsh.zwc

teardown
