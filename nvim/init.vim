call plug#begin("~/.local/share/nvim/vim-plug")

Plug 'MultisampledNight/unsweetened'
Plug 'MultisampledNight/silentmission'
Plug 'MultisampledNight/samplednight'

Plug 'DingDean/wgsl.vim'
Plug 'ap/vim-css-color'
Plug 'nvim-treesitter/nvim-treesitter'
Plug 'sheerun/vim-polyglot'
Plug 'lukas-reineke/indent-blankline.nvim'
Plug 'xuhdev/vim-latex-live-preview'

call plug#end()


" general settings
colorscheme unsweetened

set guifont=Roboto\ Mono:h11
set termguicolors
set number
set noshowmode
set title

set clipboard+=unnamedplus
set mouse=a
set completeopt=menuone,noselect
set smartcase

let mapleader = " "
let localleader = " "

" neovide
hi! Normal guibg=#171c1c ctermfg=8 guifg=#b8b2b8
let g:neovide_refresh_rate = 60
let g:neovide_cursor_animation_length = 0.065
let g:neovide_cursor_vfx_mode = "pixiedust"
let g:neovide_cursor_vfx_particle_lifetime = 6.9
let g:neovide_cursor_vfx_particle_speed = 9
let g:neovide_cursor_vfx_particle_density = 18
let g:neovide_cursor_vfx_particle_opacity = 30.0

" rust
let g:rustfmt_autosave = 1

" latex live preview
let g:livepreview_previewer = "okular"
let g:livepreview_engine = "latexmk"

lua <<EOF
require("nvim-treesitter.configs").setup {
	highlight = {
		enable = true,
	},
}

require("indent_blankline").setup {
	char = "│",
	use_treesitter = true,
	filetype = { "rust", "python", "julia", "c", "latex", "vim", "html", "html.handlebars" },
}
EOF
