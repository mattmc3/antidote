@echo "=== source ==="

0=${(%):-%N}
source ${0:a:h}/includes/setup_teardown.zsh

setup "fakes"

# before sourcing fake preztno
funcdir=$PZ_PLUGIN_HOME/preztno/modules/soarin/functions
@test "soarin foo function file should exist" -f $funcdir/foo
@test "\$fpath should not contain foo's function path" $fpath[(I)${funcdir}] -eq 0
@test "preztno fake soarin plugin is not sourced" -z $soarin

pz source preztno modules/soarin

# after sourcing fake preztno
@test "preztno fake soarin plugin sourced successfully" $? -eq 0
@test "preztno fake soarin plugin set the \$soarin variable correctly" "$soarin" = loaded
@test "\$fpath should contain soarin plugin path" $fpath[(I)$PZ_PLUGIN_HOME/preztno/modules/soarin] -ne 0
@test "\$fpath should contain soarin's foo function path" $fpath[(I)${funcdir}] -ne 0

teardown
unset funcdir
