0=${(%):-%x}
@echo "=== ${0:t:r} ==="

autoload -Uz ${0:a:h}/functions/setup && setup

() {
  local output expected actual err
  setup_plugin foo/bar "unsetopt noaliases" "setopt autocd"

  # setup
  setopt noaliases

  # verify starting state
  actual=($(set -o | grep noaliases))
  expected=(noaliases on)
  @test "starting state noaliases val='on'" "$expected" = "$actual"
  actual=($(set -o | grep autocd))
  expected=(autocd off)
  @test "starting state autocd val='off'" "$expected" = "$actual"

  # load the plugin and see if the option is now on
  antidote load; err=$?
  @test "'antidote load' succeeds" $err -eq 0
  actual=($(set -o | grep noaliases))
  expected=(noaliases off)
  @test "'antidote load' changed noaliases to 'off'" "$expected" = "$actual"
  actual=($(set -o | grep autocd))
  expected=(autocd on)
  @test "'antidote load' changed autocd to 'on'" "$expected" = "$actual"

  # teardown
  unsetopt noaliases
  unsetopt autocd
}

# Run this test last!
# It sets all nearly every option.
# Cue Grizwold lighting ceremony!!!
() {
  local all_the_opts ignore_opts opt_cmds new_opts key val oldval err
  local old_count new_count

  typeset -a opt_cmds=()
  typeset -A all_the_opts=($(set -o))
  typeset -a ignore_opts=(
    emacs
    noglobalrcs
    interactive
    kshoptionprint
    localoptions
    login
    monitor
    noexec
    norcs
    priviledged
    nopromptpercent
    restricted
    shinstdin
    singlecommand
    sourcetrace
    verbose
    vi
    xtrace
    zle
  )

  for key val in "${(@kv)all_the_opts}"; do
    (($ignore_opts[(Ie)$key])) && continue
    if [[ "$val" == "off" ]]; then
      opt_cmds+=("setopt $key")
    else
      opt_cmds+=("unsetopt $key")
    fi
  done

  # generate a foo/bar plugin that sets all the options
  setup_plugin foo/bar ${(o)opt_cmds}

  actual=($(setopt | wc -l))
  expected=5
  @test "enabled options is $expected" $expected = $actual

  antidote load 2>&1; err=$?
  @test "'antidote load' succeeds" $err -eq 0

  actual=($(setopt | wc -l))
  expected=161
  @test "enabled options is $expected" $expected = $actual
}

teardown
