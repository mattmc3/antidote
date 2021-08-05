0=${(%):-%N}
@echo "=== ${0:t:r} ==="

source ${0:a:h}/includes/setup_teardown.zsh
setup

# before cloning OMZ
@test "ohmyzsh directory should not exist" ! -d $PZ_PLUGIN_HOME/ohmyzsh
@test "ohmyzsh init script should not exist" ! -f $PZ_PLUGIN_HOME/ohmyzsh/oh-my-zsh.sh

# clone OMZ
pz clone ohmyzsh/ohmyzsh > /dev/null 2>&1

# after cloning OMZ
@test "pz clone ohmyzsh/ohmyzsh" $? -eq 0
@test "ohmyzsh directory exists" -d $PZ_PLUGIN_HOME/ohmyzsh
@test "ohmyzsh init script exists" -f $PZ_PLUGIN_HOME/ohmyzsh/oh-my-zsh.sh

# clone and rename a repo
@test "autosuggest directory should not exist yet" ! -d $PZ_PLUGIN_HOME/autosuggest
@test "zsh-autosuggestions directory should not exist" ! -d $PZ_PLUGIN_HOME/zsh-autosuggestions
pz clone zsh-users/zsh-autosuggestions autosuggest > /dev/null 2>&1
@test "pz clone zsh-users/zsh-autosuggestions autosuggest" $? -eq 0
@test "autosuggest directory should now exist" -d $PZ_PLUGIN_HOME/autosuggest
@test "zsh-autosuggestions directory should still not exist" ! -d $PZ_PLUGIN_HOME/zsh-autosuggestions

# clone a non-existing repo
pz clone void/doesnotexist > /dev/null 2>&1
@test "pz clone mattmc3/doesnotexist" $? -ne 0
@test "doesnotexist directory should not exist" ! -d $PZ_PLUGIN_HOME/doesnotexist

teardown
