" File: treesitterfun.vim
" Author: MultisampledNight (multisn8)

lua <<EOF
require'nvim-treesitter.configs'.setup {
	highlight = {
		enable = true,
	},
	rainbow = {
		enable = true,
	},
}
EOF
