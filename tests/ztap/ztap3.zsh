function ztap_header {
  [[ -n "$1" ]] && @echo "=== ${1} ==="
}
function ztap_footer {}

###
### ztap3
###
### An implementation of the Test Anything Protocol (https://testanything.org)
### for Zsh.
###
### Source: https://github.com/mattmc3/ztap
### License: MIT
###

# 0=${(%):-%x}
# ZTAP_HOME=${0:A:h}
# ZTAP_VERSION=3.0.0
# ZTAP_TESTNUM=${ZTAP_TESTNUM:-1}
# ZTAP_PASSED=0
# ZTAP_FAILED=0
# typeset -Ag ZTAP_OPERATORS=(
#   '-b'  "file exists and is a block special file"
#   '-c'  "file exists and is a character special file"
#   '-d'  "directory exists"
#   '-e'  "file/directory exists (regardless of type)"
#   '-f'  "regular file exists"
#   '-g'  "file/directory exists and group ID flag is set"
#   '-h'  "file/directory exists and is a symbolic link (do not rely on this, use -L)"
#   '-k'  "file/directory exists and its sticky bit is set"
#   '-n'  "length of string is nonzero"
#   '-p'  "file is a named pipe (FIFO)"
#   '-r'  "file/directory exists and is readable"
#   '-s'  "file exists and has a size greater than zero"
#   '-t'  "a terminal descriptor"
#   '-u'  "file/directory exists and user ID flag is set"
#   '-w'  "file/directory exists and is writable"
#   '-x'  "file/directory exists and is executable"
#   '-z'  "length of string is zero"
#   '-L'  "file/directory exists and is a symbolic link"
#   '-O'  "file/directory is owned by the current user"
#   '-G'  "file/directory with same group ID as the current user"
#   '-S'  "file exists and is a socket"
#   '-nt'  "file1 exists and is newer than file2"
#   '-ot'  "file1 exists and is older than file2"
#   '-ef'  "file1 and file2 exist and refer to the same file"
#   '-eq'  "integers n1 and n2 are algebraically equal"
#   '-ne'  "integers n1 and n2 are not algebraically equal"
#   '-gt'  "integer n1 is algebraically greater than the integer n2"
#   '-ge'  "integer n1 is algebraically greater than or equal to the integer n2"
#   '-lt'  "integer n1 is algebraically less than the integer n2"
#   '-le'  "integer n1 is algebraically less than or equal to the integer n2"
#   '='    "strings s1 and s2 are identical"
#   '!='   "strings s1 and s2 are not identical"
#   ''     "value is non-empty"
# )
# ZTAP_ONEARG_TESTS=(-{b,c,d,e,f,g,h,k,n,p,r,s,t,u,w,x,z,L,O,G,S})
# ZTAP_TWOARG_TESTS=(-{nt,ot,ef,eq,ne,gt,ge,lt,le} '=' '!=')
# if [[ -n "$XDG_CACHE_HOME" ]]; then
#   ZTAP_CACHE_HOME=$XDG_CACHE_HOME/ztap
# else
#   ZTAP_CACHE_HOME=$ZTAP_HOME/.cache
# fi
# mkdir -p "$ZTAP_CACHE_HOME"

# o_ztap_chain=()
# for _opt in $@; do
#   if [[ $_opt == "--ztap-chain" ]]; then
#     o_ztap_chain+=($_opt)
#   fi
# done
# unset _opt

# function scrub {
#   1=${1//$'\t'/'\\t'}
#   1=${1//$'\r'/'\\r'}
#   1=${1//$'\n'/'\\n'}
#   REPLY=$1
#   echo $REPLY
# }

# function @echo {
#   printf "# %s\n" "${(f)@}"
# }

# function @bailout {
#   echo "Bail out!" "$@"
# }

# function @test {
#   local REPLY; scrub "$1" &>/dev/null; 1=$REPLY
#   local test_result="ok ${ZTAP_TESTNUM} $1"; shift
#   (( ZTAP_TESTNUM = ZTAP_TESTNUM + 1 ))
#   if test "$@"; then
#     (( ZTAP_PASSED = ZTAP_PASSED + 1 ))
#     echo $test_result
#   else
#     (( ZTAP_FAILED = ZTAP_FAILED + 1 ))
#     echo "not $test_result"
#     ztap_failure_details "$@" || {
#       echo "  failed test ${(q-)@}"
#       echo "  ..."
#     }
#     return 1
#   fi
# }

# function ztap_failure_details {
#   local not notword
#   if [[ $1 == "!" ]]; then
#     not="!"; notword="*NOT* "; shift
#   fi

#   local oper= values=()
#   if [[ $# -eq 1 ]]; then
#     values=("${(q-)1}")
#   elif [[ $# -eq 2 ]] && [[ ${ZTAP_ONEARG_TESTS[(Ie)$1]} ]]; then
#     oper=$1
#     values=("${(q-)2}")
#   elif [[ $# -eq 3 ]] && [[ ${ZTAP_TWOARG_TESTS[(Ie)$2]} ]]; then
#     oper=$2
#     values=("${(q-)1}" "${(q-)3}")
#   else
#     @echo "params: $@"
#     return 1
#   fi

#   local oper_desc="${notword}${ZTAP_OPERATORS[${oper}]}"
#     echo "  operator: ${not}${oper} (${oper_desc})"
#   local idx=0 val
#   for val in "${values[@]}"; do
#     (( idx = $idx + 1 ))
#     echo "  value${idx}:   $val"
#   done
#   echo "  ..."
# }

# function ztap_header {
#   (( ! $#o_ztap_chain )) && echo TAP version 13
#   [[ -n "$1" ]] && @echo "=== ${1} ==="
# }

# function ztap_footer {
#   if (( $#o_ztap_chain )); then
#     # the footer for ztap chaining is its state on fd3
#     (( ZTAP_TESTS = $ZTAP_PASSED + $ZTAP_FAILED ))
#     >&3 echo "export ZTAP_PASSED=$ZTAP_PASSED"
#     >&3 echo "export ZTAP_FAILED=$ZTAP_FAILED"
#     >&3 echo "export ZTAP_TESTNUM=$ZTAP_TESTNUM"
#     >&3 echo "export ZTAP_TESTS=$ZTAP_TESTS"
#   else
#     local total
#     (( total = $ZTAP_PASSED + $ZTAP_FAILED ))

#     echo ""
#     echo "1..${total}"
#     echo "# pass $ZTAP_PASSED"
#     if [[ $ZTAP_FAILED -eq 0 ]]; then
#       echo "# ok"
#     else
#       echo "# fail $ZTAP_FAILED"
#       return 1
#     fi
#   fi
# }

# function ztap3 {
#   local failed_files=()
#   local statefile="$ZTAP_CACHE_HOME/.ztap-state-$(date +%Y%m%dT%H%M%SZ).zsh"
#   local file errfile stderr exitcode
#   local pass_total fail_total

#   ztap_header

#   for file in $@; do
#     errfile="$ZTAP_CACHE_HOME/.ztap-${file:r:t}-stderr-$(date +%Y%m%dT%H%M%SZ).zsh"
#     $file --ztap-chain 2>$errfile 3>$statefile
#     exitcode=$?
#     stderr=$(<$errfile)

#     if [[ -n "$stderr" ]]; then
#       @echo "WARNING: tests wrote to stderr!"
#       @echo "stderr: ${(q-)stderr}"
#     fi

#     if [[ $exitcode -ne 0 ]]; then
#       @bailout "Error with ${file:t}."
#       return 2
#     fi
#     if [[ -s $statefile ]]; then
#       source $statefile
#     else
#       @bailout "Test file did not report state. Be sure to call 'ztap_footer'."
#       return 2
#     fi
#     (( pass_total = $pass_total + $ZTAP_PASSED ))
#     (( fail_total = $fail_total + $ZTAP_FAILED ))
#     if [[ $ZTAP_FAILED -gt 0 ]]; then
#       failed_files+=($file)
#     fi
#   done
#   ZTAP_PASSED=$pass_total
#   ZTAP_FAILED=$fail_total

#   if (( $#failed_files )); then
#     @echo "=== TEST FILE FAILURES: ${#failed_files}/$# ==="
#     for file in $failed_files; do
#       @echo "FAIL: ${file:t:r}"
#     done
#   fi

#   ztap_footer

#   # clean up
#   for file in $ZTAP_CACHE_HOME/.ztap-*(N); do
#     rm -rf $file
#   done

#   [[ $fail_total -eq 0 ]] || return 1
# }
