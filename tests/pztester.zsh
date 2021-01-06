#!/usr/bin/env zsh

THIS_SCIRPT=${(%):-%N}
autoload colors; colors
PZ_PLUGIN_HOME=$(mktemp -d)
puts "created temporary PZ_PLUGIN_HOME: $PZ_PLUGIN_HOME"

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
  typeset -g successes fails
  successes=0
  fails=0
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

function test_clone_ohmyzsh() {
  puts "test cloning ohmyzsh/ohmyzsh..."
  pz clone ohmyzsh/ohmyzsh
  assert_directory_exists $PZ_PLUGIN_HOME/ohmyzsh
  assert_file_exists $PZ_PLUGIN_HOME/ohmyzsh/oh-my-zsh.sh
  del $PZ_PLUGIN_HOME/ohmyzsh
}

function test_pz_list() {
  local plugins=($(_pz_list -s))
  assert_equals 6 ${#plugins[@]}
}

function assert() {
  if test $1 -ne 0; then
    echo "$fg[red]${2}${reset_color}" >&2
    ((fails = fails + 1))
    return 1
  fi
  ((successes = successes + 1))
}

function assert_equals() {
  test "$1" = "$2"
  assert $? "$0 fail: expected $1, actual $2"
}

function assert_directory_exists() {
  test -d "$1"
  assert $? "$0 fail: directory does not exist: $1"
}

function assert_file_exists() {
  test -f "$1"
  assert $? "$0 fail: file does not exist: $1"
}

function test_pz_source_file() {
  local sf
  sf=$(__pz_get_source_file zsh-incompletions)
  assert_equals $PZ_PLUGIN_HOME/zsh-incompletions/zsh-incompletions.plugin.zsh $sf
  sf=$(__pz_get_source_file fakemyzsh)
  assert_equals $PZ_PLUGIN_HOME/fakemyzsh/fake-my-zsh.sh $sf
  sf=$(__pz_get_source_file fakemyzsh lib/one.zsh)
  assert_equals $PZ_PLUGIN_HOME/fakemyzsh/lib/one.zsh $sf
  sf=$(__pz_get_source_file fakemyzsh lib/two)
  assert_equals $PZ_PLUGIN_HOME/fakemyzsh/lib/two.zsh $sf
  sf=$(__pz_get_source_file fakemyzsh plugins/foobar)
  assert_equals $PZ_PLUGIN_HOME/fakemyzsh/plugins/foobar/foobar.plugin.zsh $sf
  sf=$(__pz_get_source_file fakemyzsh themes/russellbobby)
  assert_equals $PZ_PLUGIN_HOME/fakemyzsh/themes/russellbobby.zsh-theme $sf
  sf=$(__pz_get_source_file preztno modules/soarin)
  assert_equals $PZ_PLUGIN_HOME/preztno/modules/soarin/init.zsh $sf
  sf=$(__pz_get_source_file upper.zsh)
  assert_equals $PZ_PLUGIN_HOME/upper.zsh/upper.plugin.zsh $sf
  sf=$(__pz_get_source_file zee)
  assert_equals $PZ_PLUGIN_HOME/zee/zee.sh $sf
  sf=$(__pz_get_source_file notaplugin)
  assert_equals '' $sf
}

function show_assert_results() {
  echo "----------"
  echo $fg[green]"Successful assertions: ${successes}"${reset_color}
  echo $fg[red]"Failed assertions: ${fails}"${reset_color}
  local total
  (( total = $successes + $fails ))
  echo $fg[cyan]"Total assertions: ${total}"${reset_color}
}

() {
  setup

  test_clone_ohmyzsh

  setup_fake_plugins
  test_pz_list
  test_pz_source_file
  teardown_fake_plugins

  teardown
  show_assert_results
}
