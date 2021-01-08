successes=0
fails=0
autoload colors; colors

function assert() {
  if test $1 -ne 0; then
    echo "$fg[red]fail!!! ${2}${reset_color}" >&2
    ((fails = fails + 1))
    return 1
  fi
  ((successes = successes + 1))
}

function assert_equals() {
  local err=${3:-$0 - expected $1, actual $2}
  test "$1" = "$2"
  assert $? $err
}

function assert_not_equals() {
  local err=${3:-$0 - expected $1, actual $2}
  test "$1" != "$2"
  assert $? $err
}

function assert_function_exists() {
  local err=${2:-$0 - function does not exist: $1}
  (( $+functions[$1] ))
  assert $? $err
}

function assert_function_not_exists() {
  local err=${2:-$0 - function exists: $1}
  (( ! $+functions[$1] ))
  assert $? $err
}

function assert_path_contains() {
  local err=${2:-$0 - path does not contain: $1}
  test $path[(I)${1}] -ne 0
  assert $? $err
}

function assert_path_not_contains() {
  local err=${2:-$0 - path contains: $1}
  test $path[(I)${1}] -eq 0
  assert $? $err
}

function assert_fpath_contains() {
  local err=${2:-$0 - fpath does not contain: $1}
  test $fpath[(I)${1}] -ne 0
  assert $? $err
}

function assert_fpath_not_contains() {
  local err=${2:-$0 - fpath contains: $1}
  test $fpath[(I)${1}] -eq 0
  assert $? $err
}

function assert_directory_not_exists() {
  local err=${2:-$0 - directory exists: $1}
  test ! -d "$1"
  assert $? $err
}

function assert_directory_exists() {
  local err=${2:-$0 - directory does not exist: $1}
  test -d "$1"
  assert $? $err
}

function assert_file_not_exists() {
  local err=${2:-$0 - file exists: $1}
  test ! -f "$1"
  assert $? $err
}

function assert_file_exists() {
  local err=${2:-$0 - file does not exist: $1}
  test -f "$1"
  assert $? $err
}

function print_assertion_results() {
  echo "----------"
  echo $fg[green]"Successful assertions: ${successes}"${reset_color}
  echo $fg[red]"Failed assertions: ${fails}"${reset_color}
  local total
  (( total = $successes + $fails ))
  echo $fg[cyan]"Total assertions: ${total}"${reset_color}
}
