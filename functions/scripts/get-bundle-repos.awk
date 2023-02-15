# get a list of clonable repos from a bundle file

# initialize vars
{ branch=""; url="" }

# skip blank or commented lines
/^ *(#.+)?$/ { next }

/kind:defer/ { print "https://github.com/romkatv/zsh-defer" }

# handle user/repo form by converting to full git URL
$1~/^[^\/]+\/[^\/]+$/ { url="https://github.com/" $1 }

# handle regular git URL lines
$1~/^(https?:|(ssh|git)@)/ {url=$1}

# find branch annotation if it exists
match($0, /branch:[^\t ]+/) { branch="--branch " substr($0, RSTART+7, RLENGTH-7) }

# print result
url!=""{ if(branch!="") print url, branch; else print url }
