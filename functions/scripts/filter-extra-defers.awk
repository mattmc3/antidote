# filter all but the first time we source zsh-defer (a 4 line if statement)
BEGIN   { skip=0; found=0 }
skip>0  { skip-- }
/^if.+functions\[zsh\-defer\]/ { if(!found) found=1; else skip=4 }
skip==0 { print }
