# skip comments and empty lines
/^ *$/ || /^ *#/ {next}

# strip trailing comments
{ sub(/[ \t]#.*$/,"",$0) }

# handle extension functionality (eg ':use ohmyzsh')
$1~/^:/ {
  sub(/^:/,"",$1)
  printf "antidote-script-" $1
  for (i=2; i<=NF; i++) {
    printf " %s",$i
  }
  printf "\n"
  next
}

# move flags to front and call antidote-script
{
  sub(/ #.*$/,"",$0)
  printf "antidote-script"
  for (i=2; i<=NF; i++) {
    sub(/^/,"--",$i)
    sub(/:/," ",$i)
    printf " %s",$i
  }
  printf " %s\n",$1
}
