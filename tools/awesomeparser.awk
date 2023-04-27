#!/usr/bin/awk -f

# Parse readme from unixorn/awesome-zsh-plugins

# ignore blank lines
/^$/ {next}
# ignore until we get '#+ Header'
/^#+ / {
  tolower($2) == tolower(header) ? p=1 : p=0; next
}
# print if we're in the selected header
p{print}


#/^$/{next}/^#+ /{tolower($2)==tolower(header)?p=1:p=0;next}p{print}

#./tools/awesomeparser.awk -v header=plugins $readme | gsed -E -e 's|^- \[[^]]+\]\(https://github.com/([^/]+)/([^/\)]+)\)|\\1/\\2|g' -e 's|\[([^]]+)\]\([^\)]+\)|\1|g' | sort | cat -n | fzf --with-nth 2.. | awk '{print $1}'


# awk -v header=plugins '/^$/{next}/^#+ /{tolower($2)==header?p=1:p=0;next}p{print}' $readme |
# sed -E -e 's|^- ||' -e 's|^\[([^]]+)\]\([^\)]+\)|\1|' -e 's|\[([^]]+)\]\([^\)]+\)|\1|g' |
# sort > awesome_plugins.txt


awk -v header=plugins '/^$/{next}/^#+ /{tolower($2)==header?p=1:p=0;next}p{print}' $readme |
sed -E -e 's|^- ||' \
       -e 's|^\[[^]]+\]\(https://[^\.]+.com/([^/]+)/([^/\)]+)\)( ?- ?)?|\2 (\1/\2) :: |g' \
       -e 's|\[([^]]+)\]\([^\)]+\)|\1|g' >| awesome_plugins.txt

# sort > awesome_plugins.txt

cat -n awesome_plugins.txt | fzf -e --with-nth=2.. --preview='echo {2..}' --preview-window='wrap' | awk '{print $1}'


# awk -v header=plugins '/^$/{next}/^#+ /{tolower($2)==header?p=1:p=0;next}p{print}' $readme |
# sed -E -e 's|^- ||' -e 's|^\[([^]]+)\]\([^\)]+\)|\1|' -e 's|\[([^]]+)\]\([^\)]+\)|\1|g' |
# sort | cat -n | fzf -e --with-nth=2.. --preview='echo {2..}' --preview-window='wrap' | awk '{print $1}'

# sed -E -e 's|^- \[[^]]+\]\(https://[^\.]+.com/([^/]+)/([^/\)]+)\)( ?- ?)?|\1/\2 |g' -e 's|\[([^]]+)\]\([^\)]+\)|\1|g' |
# sort | cat -n | fzf --with-nth 2.. | awk '{print $1}'


# ./tools/awesomeparser.awk -v header=plugins $readme | gsed -E -e 's|^- \[[^]]+\]\(https://github.com/([^/]+)/([^/\)]+)\)|\\1/\\2|g' -e 's|\[([^]]+)\]\([^\)]+\)|\1|g' |
# sort | cat -n | fzf --with-nth 2.. | awk '{print $1}'
