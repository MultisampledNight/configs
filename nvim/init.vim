""" PLUGINS

call plug#begin('~/.local/share/nvim/vim-plug-stuff')

" normal
Plug 'wellle/context.vim'
Plug 'TornaxO7/auto-cosco.vim', {'branch': 'stable'}
Plug 'MultisampledNight/samplednight'
Plug 'itchyny/lightline.vim'
Plug 'preservim/nerdtree'

" latex or something, idk
Plug 'xuhdev/vim-latex-live-preview'

" nightly, at your own risk!
if has('nvim-0.5')
	Plug 'nvim-treesitter/nvim-treesitter'
	Plug 'neovim/nvim-lspconfig'
	Plug 'ray-x/lsp_signature.nvim'
	Plug 'folke/lsp-trouble.nvim'
	Plug 'simrat39/symbols-outline.nvim'
	Plug 'lukas-reineke/indent-blankline.nvim', {'branch': 'lua'}
	" bugs around with auto-cosco.vim, so disable it... for now
	"Plug 'hrsh7th/nvim-compe'
endif

call plug#end()

source ~/.config/nvim/helpers/general.vim
source ~/.config/nvim/helpers/visual.vim
source ~/.config/nvim/helpers/lightline.vim
source ~/.config/nvim/helpers/rust.vim

"" nightly stuff
if has('nvim-0.5')
	"source ~/.config/nvim/helpers/compefun.vim
	source ~/.config/nvim/helpers/lspconfigfun.vim
	source ~/.config/nvim/helpers/treesitterfun.vim
	source ~/.config/nvim/helpers/lsp-trouble.vim
	source ~/.config/nvim/helpers/symbols-outline.vim
	source ~/.config/nvim/helpers/indent-blankline.vim
endif
