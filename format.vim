" Vim script for formatting the file containing quotes

" AIMED FORMAT:
" 	{quote1} --- {author1}
" 	{quote2} --- {author2}
" 	[...]

" Remove comments '# ...'
:%s/^#.*//
" Removes empty lines
:%s/^\s\+//
:%s/^\n\+//
" Make line of two '='-separated fields (quote=source)
:%s/\n--- /@/
