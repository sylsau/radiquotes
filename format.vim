" Vim script for formatting the file containing quotes

" AIMED FORMAT:
" 	{quote1}@{source}
" 	{quote2}@{source}
" 	[...]

" Remove comments '# ...'
:%s/^#.*//
" Removes empty lines
:%s/^\s\+//
:%s/^\n\+//
" Turns " to UTF-8 alternatives
:%s/ "\(\w\)/“\1/g
:%s/\(\w\)" /\1”/g
" No spaces around guillemets to differentiate them from whole quote guillemets
:%s/ »/»/g
:%s/« /«/g
" Unbreakable UTF-8 spaces (disabled bc it breaks IM text formatting sometimes)
":%s/« /«\\u00A0/g
":%s/ »/\\u00A0»/g
":%s/ \([!?;:]\)/\\u00A0\1/g
" Make line of two '='-separated fields (quote=source)
:%s/\n--- /@/
