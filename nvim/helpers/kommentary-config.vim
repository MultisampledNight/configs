" File: kommentary-config.vim
" Author: MultisampledNight (multisn8)

lua << EOF
require('kommentary.config').configure_language("rust", {
	prefer_single_line_comments = true,
})
EOF
