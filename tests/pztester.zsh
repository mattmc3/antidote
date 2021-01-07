#!/usr/bin/env zsh

THIS_SCIRPT=${(%):-%N}

function puts() {
  echo "$fg[cyan]${@}${reset_color}"
}

function del() {
  # let's make sure we safely rm our temp area
  if [[ -z $PZ_PLUGIN_HOME ]] || { [[ $1 != $PZ_PLUGIN_HOME/* && $1 != $PZ_PLUGIN_HOME ]] }; then
    echo $fg[red]"Unsafe delete attempted: $@"${reset_color}
  else
    rm -rf $1
  fi
}

function setup() {
  puts "sourcing pz"
  source ${THIS_SCIRPT:a:h:h}/pz.zsh
  assert $? "sourcing of pz.zsh failed"
}

function teardown() {
  puts "teardown..."
  if [[ $PZ_PLUGIN_HOME != /var/folders/* &&
        $PZ_PLUGIN_HOME != /tmp/* ]]
  then
    puts "Unexpected temp plugins dir: $PZ_PLUGIN_HOME"
  else
    puts "removing $PZ_PLUGIN_HOME"
    del "$PZ_PLUGIN_HOME"
  fi
}

function setup_fake_plugins() {
  # zsh-incompletions (zsh-users/zsh-completions fake)
  puts "creating fake plugin: zsh-incompletions"
  mkdir -p $PZ_PLUGIN_HOME/zsh-incompletions
  touch $PZ_PLUGIN_HOME/zsh-incompletions/zsh-incompletions.plugin.zsh
  touch $PZ_PLUGIN_HOME/zsh-incompletions/zsh-incompletions.zsh

  # fake-my-zsh (ohmyzsh/ohmyzsh fake)
  puts "creating fake plugin: fakemyzsh"
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
  puts "creating fake plugin: preztno"
  mkdir -p $PZ_PLUGIN_HOME/preztno/modules/soarin
  touch $PZ_PLUGIN_HOME/preztno/modules/soarin/init.zsh

  # upper (peterhurford/up.zsh fake)
  puts "creating fake plugin: upper"
  mkdir -p $PZ_PLUGIN_HOME/upper.zsh
  touch $PZ_PLUGIN_HOME/upper.zsh/upper.plugin.zsh

  # zee (rupa/z fake)
  puts "creating fake plugin: zee"
  mkdir -p $PZ_PLUGIN_HOME/zee
  touch $PZ_PLUGIN_HOME/zee/zee.sh

  # notaplugin
  puts "creating fake plugin: notaplugin"
  mkdir -p $PZ_PLUGIN_HOME/notaplugin
  touch $PZ_PLUGIN_HOME/notaplugin/README.md
}

function teardown_fake_plugins() {
  local d
  for d in $PZ_PLUGIN_HOME/*(/); do
    puts removing $d
    del $d
  done
}

function test_clone_nonexistent_plugin() {
  puts "test cloning ohmyzsh/ohmyzsh..."
  pz clone mattmc3/doesnotexist
  local exitstatus=$?
  assert_not_equals 0 $exitstatus "Unexpected exit status"
  assert_not_directory_exists $PZ_PLUGIN_HOME/doesnotexist
}

function test_clone_ohmyzsh() {
  puts "test cloning ohmyzsh/ohmyzsh..."
  pz clone ohmyzsh/ohmyzsh
  assert_directory_exists $PZ_PLUGIN_HOME/ohmyzsh
  assert_file_exists $PZ_PLUGIN_HOME/ohmyzsh/oh-my-zsh.sh
  del $PZ_PLUGIN_HOME/ohmyzsh
}

function test_source_not_yet_cloned_plugin() {
  puts "test sourcing a plugin that needs cloned first..."
  assert_directory_not_exists $PZ_PLUGIN_HOME/zsh-tailf
  assert_file_not_exists $PZ_PLUGIN_HOME/zsh-tailf/tailf.plugin.zsh
  assert_function_not_exists "tailf"

  pz source rummik/zsh-tailf

  assert_directory_exists $PZ_PLUGIN_HOME/zsh-tailf
  assert_file_exists $PZ_PLUGIN_HOME/zsh-tailf/tailf.plugin.zsh
  assert_function_exists "tailf"
  del $PZ_PLUGIN_HOME/zsh-tailf
}

function test_pz_list() {
  local plugins=($(pz list))
  assert_equals 6 ${#plugins[@]}
}

function test_pz_source_file() {
  local sf
  sf=$(pz initfile zsh-incompletions)
  assert_equals $PZ_PLUGIN_HOME/zsh-incompletions/zsh-incompletions.plugin.zsh $sf
  sf=$(pz initfile fakemyzsh)
  assert_equals $PZ_PLUGIN_HOME/fakemyzsh/fake-my-zsh.sh $sf
  sf=$(pz initfile fakemyzsh lib/one.zsh)
  assert_equals $PZ_PLUGIN_HOME/fakemyzsh/lib/one.zsh $sf
  sf=$(pz initfile fakemyzsh lib/two)
  assert_equals $PZ_PLUGIN_HOME/fakemyzsh/lib/two.zsh $sf
  sf=$(pz initfile fakemyzsh plugins/foobar)
  assert_equals $PZ_PLUGIN_HOME/fakemyzsh/plugins/foobar/foobar.plugin.zsh $sf
  sf=$(pz initfile fakemyzsh themes/russellbobby)
  assert_equals $PZ_PLUGIN_HOME/fakemyzsh/themes/russellbobby.zsh-theme $sf
  sf=$(pz initfile preztno modules/soarin)
  assert_equals $PZ_PLUGIN_HOME/preztno/modules/soarin/init.zsh $sf
  sf=$(pz initfile upper.zsh)
  assert_equals $PZ_PLUGIN_HOME/upper.zsh/upper.plugin.zsh $sf
  sf=$(pz initfile zee)
  assert_equals $PZ_PLUGIN_HOME/zee/zee.sh $sf
  sf=$(pz initfile notaplugin)
  assert_equals '' $sf
}

autoload colors; colors
PZ_PLUGIN_HOME=$(mktemp -d)
puts "created temporary PZ_PLUGIN_HOME: $PZ_PLUGIN_HOME"
source "${THIS_SCIRPT:a:h}/assertions.zsh"

() {
  setup

  test_clone_nonexistent_plugin
  test_clone_ohmyzsh
  test_source_not_yet_cloned_plugin

  setup_fake_plugins
  test_pz_list
  test_pz_source_file
  teardown_fake_plugins

  teardown
  print_assertion_results
}
