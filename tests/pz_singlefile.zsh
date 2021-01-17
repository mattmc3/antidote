0=${(%):-%N}
@echo "=== ${0:t:r} ==="

tmpdir=$(mktemp -d)

# make a standalone PZ file
mkdir $tmpdir/pz
cp ${0:a:h:h}/pz.zsh $tmpdir/pz

@test 'PZ_PLUGIN_HOME not set' -z $PZ_PLUGIN_HOME
source $tmpdir/pz/pz.zsh
@test 'PZ_PLUGIN_HOME set after sourcing pz' "$PZ_PLUGIN_HOME" = $ZDOTDIR/plugins
@test 'PZ_PLUGIN_HOME directory should not be created yet' ! -d "$PZ_PLUGIN_HOME"

# let's not really create the plugins in ZTAP's rcs directory
PZ_PLUGIN_HOME=$tmpdir/plugins

# test that extended help degrades gracefully to regular help in single file mode
pzhelp=("${(@f)$(pz help list)}")
@test 'count of help lines is 14' ${#pzhelp[@]} -eq 14
[[ ${pzhelp[1]} = "pz - "* ]]
@test '`pz help` gives us a tagline' $? -eq 0
@test '`pz help` tells us usage' ${pzhelp[3]} = "usage:"
@test '`pz help` gives us the commands it uses' ${pzhelp[6]} = "commands:"

# test that source+cloning still works
pz source ohmyzsh/ohmyzsh plugins/extract > /dev/null 2>&1
@test 'pz source+clone OMZ succeeded' $? -eq 0
@test 'OMZ files exist' -f $PZ_PLUGIN_HOME/ohmyzsh/oh-my-zsh.sh
@test 'OMZ files exist where we expected them in tests' -f $tmpdir/plugins/ohmyzsh/oh-my-zsh.sh
@test '`pz initfile` detects OMZ files' $(pz initfile ohmyzsh) = $PZ_PLUGIN_HOME/ohmyzsh/oh-my-zsh.sh

# cleanup
rm -rf $tmpdir
unset pzhelplist
