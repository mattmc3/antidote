() {
  0=${(%):-%x}
  TESTS_HOME=${0:a:h:h}
}

setup() {
  create_fake_plugins=${1:-false}

  PZ_PLUGIN_HOME=$(mktemp -d)
  @echo "creating temp \$PZ_PLUGIN_HOME: $PZ_PLUGIN_HOME"
  source ${TESTS_HOME:h}/pz.zsh
  @test "sourcing pz.zsh" $? -eq 0

  if [[ $create_fake_plugins = true ]] || [[ $create_fake_plugins = "fakes" ]]; then
    # zsh-incompletions (zsh-users/zsh-completions fake)
    mkdir -p $PZ_PLUGIN_HOME/zsh-incompletions
    touch $PZ_PLUGIN_HOME/zsh-incompletions/zsh-incompletions.plugin.zsh
    touch $PZ_PLUGIN_HOME/zsh-incompletions/zsh-incompletions.zsh

    # fake-my-zsh (ohmyzsh/ohmyzsh fake)
    mkdir -p $PZ_PLUGIN_HOME/fakemyzsh
    mkdir -p $PZ_PLUGIN_HOME/fakemyzsh/lib $PZ_PLUGIN_HOME/fakemyzsh/plugins $PZ_PLUGIN_HOME/fakemyzsh/themes
    touch $PZ_PLUGIN_HOME/fakemyzsh/fake-my-zsh.sh
    local file
    for file in one two three; do
      touch $PZ_PLUGIN_HOME/fakemyzsh/lib/${file}.zsh
    done
    mkdir $PZ_PLUGIN_HOME/fakemyzsh/plugins/foobar
    touch $PZ_PLUGIN_HOME/fakemyzsh/plugins/foobar/foobar.plugin.zsh
    touch $PZ_PLUGIN_HOME/fakemyzsh/themes/russellbobby.zsh-theme

    # preztno (sorin-ionescu/prezto fake)
    mkdir -p $PZ_PLUGIN_HOME/preztno/modules/soarin
    echo "soarin=loaded" > $PZ_PLUGIN_HOME/preztno/modules/soarin/init.zsh
    mkdir -p $PZ_PLUGIN_HOME/preztno/modules/soarin/functions
    touch $PZ_PLUGIN_HOME/preztno/modules/soarin/functions/foo

    # upper (peterhurford/up.zsh fake)
    mkdir -p $PZ_PLUGIN_HOME/upper.zsh
    touch $PZ_PLUGIN_HOME/upper.zsh/upper.plugin.zsh

    # zee (rupa/z fake)
    mkdir -p $PZ_PLUGIN_HOME/zee
    touch $PZ_PLUGIN_HOME/zee/zee.sh

    # notaplugin
    mkdir -p $PZ_PLUGIN_HOME/notaplugin
    touch $PZ_PLUGIN_HOME/notaplugin/README.md
  fi
}

function teardown() {
  [[ -d $PZ_PLUGIN_HOME ]] || return
  if [[ $PZ_PLUGIN_HOME != /var/folders/* &&
        $PZ_PLUGIN_HOME != /tmp/* ]]
  then
    @echo "Unexpected location for temp plugins dir: $PZ_PLUGIN_HOME"
  else
    @echo "removing $PZ_PLUGIN_HOME"
    rm -rf "$PZ_PLUGIN_HOME"
  fi
}
