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
:%s/\(\W\)"\(\w\)/\1“\2/g
:%s/\(\w\)"\(\W\)/\1”\2/g
" No spaces around guillemets to differentiate them from whole quote guillemets
:%s/ »/»/g
:%s/« /«/g
" -- to UTF-8 − dashes
:%s/\([^-]\)--\([^-]\)/\1−\2/gc
" Unbreakable UTF-8 spaces (disabled bc it breaks IM text formatting sometimes)
":%s/« /«\\u00A0/g
":%s/ »/\\u00A0»/g
":%s/ \([!?;:]\)/\\u00A0\1/g
" Make line of two '='-separated fields (quote=source)
:%s/\n---\s\+/@/
" Turns multi-line quotes to '\n'-formatted string (needs 2 passes)
:%s/^\([^@]\+\)$\n/\1\\n/g
:%s/^\([^@]\+\)$\n/\1\\n/g

" Highlight source of quotes
:/@.\+$
