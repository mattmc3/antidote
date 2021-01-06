#!/usr/bin/env zsh

ZERO=${(%):-%N}
autoload colors; colors
successes=0
fails=0

function puts() {
  echo "$fg[cyan]${@}${reset_color}"
}

function del() {
  # let's make sure we safely rm our temp area
  local plugins; zstyle -s :pz: plugins-dir plugins
  if [[ -z $plugins ]] || { [[ $1 != $plugins/* && $1 != $plugins ]] }; then
    echo $fg[red]"Unsafe delete attempted: $@"${reset_color}
  else
    rm -rf $1
  fi
}

function setup() {
  puts "setup..."
  test_plugins_dir=$(mktemp -d)
  puts "creating $test_plugins_dir"
  zstyle :pz: plugins-dir $test_plugins_dir
}

function teardown() {
  puts "teardown..."
  zstyle -s ':pz:' plugins-dir test_plugins_dir
  if [[ $test_plugins_dir != /var/folders/* &&
        $test_plugins_dir != /tmp/* ]]
  then
    puts "Unexpected temp plugins dir: $test_plugins_dir"
  else
    puts "removing $test_plugins_dir"
    del "$test_plugins_dir"
  fi
}

function setup_fake_plugins() {
  local plugins file
  zstyle -s :pz: plugins-dir plugins

  # zsh-incompletions (zsh-users/zsh-completions fake)
  puts "creating fake plugin: zsh-incompletions"
  mkdir -p $plugins/zsh-incompletions
  touch $plugins/zsh-incompletions/zsh-incompletions.plugin.zsh
  touch $plugins/zsh-incompletions/zsh-incompletions.zsh

  # fake-my-zsh (ohmyzsh/ohmyzsh fake)
  puts "creating fake plugin: fakemyzsh"
  mkdir -p $plugins/fakemyzsh
  mkdir -p $plugins/fakemyzsh/lib $plugins/fakemyzsh/plugins $plugins/fakemyzsh/themes
  touch $plugins/fakemyzsh/fake-my-zsh.sh
  for file in one two three; do
    touch $plugins/fakemyzsh/lib/${file}.zsh
  done
  mkdir $plugins/fakemyzsh/plugins/foobar
  touch $plugins/fakemyzsh/plugins/foobar/foobar.plugin.zsh
  touch $plugins/fakemyzsh/themes/russellbobby.zsh-theme

  # preztno (sorin-ionescu/prezto fake)
  puts "creating fake plugin: preztno"
  mkdir -p $plugins/preztno/modules/soarin
  touch $plugins/preztno/modules/soarin/init.zsh

  # upper (peterhurford/up.zsh fake)
  puts "creating fake plugin: upper"
  mkdir -p $plugins/upper.zsh
  touch $plugins/upper.zsh/upper.plugin.zsh

  # zee (rupa/z fake)
  puts "creating fake plugin: zee"
  mkdir -p $plugins/zee
  touch $plugins/zee/zee.sh

  # notaplugin
  puts "creating fake plugin: notaplugin"
  mkdir -p $plugins/notaplugin
  touch $plugins/notaplugin/README.md
}

function teardown_fake_plugins() {
  local plugins; zstyle -s :pz: plugins-dir plugins
  local d
  for d in $plugins/*(/); do
    puts removing $d
    del $d
  done
}

function test_clone_ohmyzsh() {
  local plugins; zstyle -s :pz: plugins-dir plugins
  puts "test cloning ohmyzsh/ohmyzsh..."
  pz clone ohmyzsh/ohmyzsh
  assert_directory_exists $plugins/ohmyzsh
  assert_file_exists $plugins/ohmyzsh/oh-my-zsh.sh
  del $plugins/ohmyzsh
}

function test_pz_list() {
  plugins=($(_pz_list -s))
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
  local plugins; zstyle -s :pz: plugins-dir plugins
  local sf
  sf=$(__pz_get_source_file zsh-incompletions)
  assert_equals $plugins/zsh-incompletions/zsh-incompletions.plugin.zsh $sf
  sf=$(__pz_get_source_file fakemyzsh)
  assert_equals $plugins/fakemyzsh/fake-my-zsh.sh $sf
  sf=$(__pz_get_source_file fakemyzsh lib/one.zsh)
  assert_equals $plugins/fakemyzsh/lib/one.zsh $sf
  sf=$(__pz_get_source_file fakemyzsh lib/two)
  assert_equals $plugins/fakemyzsh/lib/two.zsh $sf
  sf=$(__pz_get_source_file fakemyzsh plugins/foobar)
  assert_equals $plugins/fakemyzsh/plugins/foobar/foobar.plugin.zsh $sf
  sf=$(__pz_get_source_file fakemyzsh themes/russellbobby)
  assert_equals $plugins/fakemyzsh/themes/russellbobby.zsh-theme $sf
  sf=$(__pz_get_source_file preztno modules/soarin)
  assert_equals $plugins/preztno/modules/soarin/init.zsh $sf
  sf=$(__pz_get_source_file upper.zsh)
  assert_equals $plugins/upper.zsh/upper.plugin.zsh $sf
  sf=$(__pz_get_source_file zee)
  assert_equals $plugins/zee/zee.sh $sf
  sf=$(__pz_get_source_file notaplugin)
  assert_equals '' $sf
}

function run_tests() {
  setup
  test_clone_ohmyzsh

  setup_fake_plugins
  test_pz_list
  test_pz_source_file
  teardown_fake_plugins

  teardown

  echo "----------"
  echo $fg[green]"Successful assertions: ${successes}"${reset_color}
  echo $fg[red]"Failed assertions: ${fails}"${reset_color}
  local total
  (( total = $successes + $fails ))
  echo $fg[cyan]"Total assertions: ${total}"${reset_color}
}

# main
source ${ZERO:a:h:h}/pz.zsh
assert $? "sourcing of pz.zsh failed"
run_tests
