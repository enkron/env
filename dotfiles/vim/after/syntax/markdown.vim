vim9script

# Extends the runtime markdown syntax, whose markdownBlockquote matches
# only the '>' marker and leaves the quoted text itself ungrouped.
# markdownBlockquoteText covers the rest of every quoted line, after any
# nested '>' markers, list markers or headings the marker's nextgroup
# claims first, and keeps inline markup and spell checking inside it.
# The lookbehind is capped at 20 bytes: the match starts at the first
# non-blank after the markers, so it never needs to look further back.
syn match markdownBlockquoteText '\%(^ \{,3}>.*\)\@20<=\S.*$' contains=@markdownInline,@Spell

hi def link markdownBlockquoteText Comment

# markdownError flags every intra-word '_' (snake_case, file_names), which
# CommonMark treats as literal text. A colorscheme cannot neutralize it: a
# group with only NONE attributes counts as cleared, so the syntax file's
# 'hi def link markdownError Error' still applies. Drop the match instead.
syn clear markdownError
