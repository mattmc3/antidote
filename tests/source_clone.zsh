@echo "=== source clone ==="

0=${(%):-%N}
source ${0:a:h}/includes/setup_teardown.zsh

setup

# before sourcing zsh-tailf
@test "zsh-tailf directory should not exist" ! -d $PZ_PLUGIN_HOME/zsh-tailf
@test "zsh-tailf init script should not exist" ! -f $PZ_PLUGIN_HOME/zsh-tailf/tailf.plugin.zsh

# source zsh-tailf
pz source rummik/zsh-tailf > /dev/null 2>&1

@test "pz source rummik/zsh-tailf" $? -eq 0
@test "zsh-tailf directory should exist" -d $PZ_PLUGIN_HOME/zsh-tailf
@test "zsh-tailf init script should exist" -f $PZ_PLUGIN_HOME/zsh-tailf/tailf.plugin.zsh
@test "tailf function should exist" -f $PZ_PLUGIN_HOME/zsh-tailf/tailf.plugin.zsh

teardown
