successes=0
fails=0
autoload colors; colors

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

function assert_not_equals() {
  test "$1" != "$2"
  assert $? "$0 fail: expected $1, actual $2"
}

function assert_function_exists() {
  (( $+functions[$1] ))
  assert $? "$0 fail: function does not exist: $1"
}

function assert_function_not_exists() {
  (( ! $+functions[$1] ))
  assert $? "$0 fail: function exists: $1"
}

function assert_directory_not_exists() {
  test ! -d "$1"
  assert $? "$0 fail: directory exists: $1"
}

function assert_directory_exists() {
  test -d "$1"
  assert $? "$0 fail: directory does not exist: $1"
}

function assert_file_not_exists() {
  test ! -f "$1"
  assert $? "$0 fail: file exists: $1"
}

function assert_file_exists() {
  test -f "$1"
  assert $? "$0 fail: file does not exist: $1"
}

function print_assertion_results() {
  echo "----------"
  echo $fg[green]"Successful assertions: ${successes}"${reset_color}
  echo $fg[red]"Failed assertions: ${fails}"${reset_color}
  local total
  (( total = $successes + $fails ))
  echo $fg[cyan]"Total assertions: ${total}"${reset_color}
}
