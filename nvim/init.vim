call plug#begin("~/.local/share/nvim/vim-plug")

Plug 'MultisampledNight/colorschemes'

Plug 'hrsh7th/nvim-cmp'
Plug 'hrsh7th/vim-vsnip'
Plug 'hrsh7th/cmp-vsnip'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-nvim-lsp'

Plug 'neovim/nvim-lspconfig'
Plug 'folke/trouble.nvim'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim', { 'branch': '0.1.x' }
Plug 'nvim-telescope/telescope-ui-select.nvim'
Plug 'wincent/ferret'

Plug 'ap/vim-css-color'
Plug 'nvim-treesitter/nvim-treesitter'
Plug 'nvim-treesitter/playground'
Plug 'sheerun/vim-polyglot'
Plug 'mhinz/vim-signify'

call plug#end()

function ProjectToplevel()
	let toplevel = trim(system("cargo metadata --format-version=1 --offline --no-deps"))
	if v:shell_error == 0
		let toplevel = json_decode(toplevel)["workspace_root"]
	else
		let toplevel = trim(system("git rev-parse --show-toplevel"))
		if v:shell_error != 0
			let toplevel = getcwd()
		endif
	endif
	return toplevel
endfunction

" general settings
if $TERM ==# "linux"
	" in a TTY neovim also serves as some sort of window manager for me
	colorscheme pablo

	hi! Identifier ctermfg=blue
	hi! Function ctermfg=magenta
	hi! Keyword ctermfg=red
	hi! Conditional ctermfg=red
	hi! Repeat ctermfg=red

	hi! LineNr ctermfg=grey
	hi! StatusLine ctermfg=blue ctermbg=black
	hi! StatusLineNC ctermfg=grey ctermbg=black

	nnoremap <A-S-j> <Cmd>2split<CR>z2<CR><Cmd>term i3status<CR><Cmd>set nonumber<CR>G<C-w>j

	nnoremap <A-S-f> <Cmd>silent !brightnessctl --exponent set 5\%-<CR>
	nnoremap <A-S-v> <Cmd>silent !brightnessctl --exponent set 3\%+<CR>
else
	colorscheme base16-abnormalize-alt
	set termguicolors

	if exists("g:neovide")
		set winblend=50
		set pumblend=50
	else
		set winblend=20
		set pumblend=20
	endif

lua <<EOF
	local capabilities = require("cmp_nvim_lsp").default_capabilities()
	local lspconfig = require("lspconfig")

	flags = { debounce_text_changes = 150 }

	lspconfig.util.default_config = vim.tbl_extend(
		"force",
		lspconfig.util.default_config,
		{
				handlers = {
					["window/showMessage"] = function(err, method, params, client_id) end;
				}
		}
	)

	lspconfig.rust_analyzer.setup {
		capabilities = capabilities,
		flags = flags,
		filetypes = {
			"rust",
			"netrw",
		},
		settings = {
			["rust-analyzer"] = {
				imports = {
					granularity = {
						group = "crate",
					},
				},
				checkOnSave = {
					command = "clippy",
					-- extraArgs = {"--", "-Wclippy::pedantic"},
				},
			}
		}
	}
	lspconfig.texlab.setup {
		capabilities = capabilities,
		flags = flags,
		filetypes = {
			"latex",
		},
	}

	require("trouble").setup({
		position = "bottom",
		height = 9,
		icons = false,
		fold_closed = ">",
		fold_open = "=",
		signs = {
			error = "#",
			warning = "!",
			hint = "?",
			information = "/",
			other = "-",
		}
	})
EOF

endif

set guifont=Roboto_Mono:h15:#e-subpixelantialias
set number
set noshowmode
set breakindent
set signcolumn=yes
set title
set titlestring=%m%h%w%F
set titlelen=0
set linebreak
set undofile
set shortmess+=W

" smarter autochdir
exe "cd " . ProjectToplevel()
set clipboard+=unnamedplus
set completeopt=menu,menuone,preview,noselect
set mouse=a
set mousemodel=extend
set mousescroll=ver:4,hor:0
set ignorecase
set smartcase
set scrolloff=2
set sidescrolloff=6
set tabstop=4

set foldmethod=expr
set foldexpr=nvim_treesitter#foldexpr()
set nofoldenable

let mapleader = " "
let localleader = " "


function SelectionToClipboard()
	if mode() == "v"
		let selection_start = getcurpos()[1:]
		silent normal! o
		let selection_end = getcurpos()[1:]

		silent normal! "*y

		call cursor(selection_start)
		silent normal! v
		call cursor(selection_end)
		silent normal! o
	endif
endfunction

" copy selection to primary clipboard
vnoremap <LeftRelease> <Cmd>call SelectionToClipboard()<cr>

" if you should ever wonder why these shortcuts seem like they're thrown
" all over the place: they're made for the Bone layout, not Qwerty
tnoremap <A-Esc> <C-\><C-N>

nnoremap <silent> j gj
nnoremap <silent> k gk
nnoremap gn n<Cmd>noh<CR>
nnoremap gN N<Cmd>noh<CR>

vnoremap j gj
vnoremap k gk
vnoremap gn n<Cmd>noh<CR>
vnoremap gN N<Cmd>noh<CR>

vnoremap <S-k> <Cmd>lua require("dapui").eval()<CR>

function TelescopeOnToplevel(command)
	exe "Telescope " . a:command . " cwd=" . ProjectToplevel()
endfunction

nnoremap tt <Cmd>Telescope resume<CR> 
nnoremap ti <Cmd>call TelescopeOnToplevel("find_files")<CR> 
nnoremap te <Cmd>call TelescopeOnToplevel("live_grep")<CR> 
nnoremap td <Cmd>Telescope lsp_definitions<CR>
nnoremap tu <Cmd>Telescope lsp_references<CR>
nnoremap ta <Cmd>Telescope lsp_implementations<CR>

nnoremap tb <Cmd>TroubleToggle<CR>
nnoremap tn <Cmd>lua vim.lsp.buf.hover()<CR>
nnoremap tr <Cmd>lua vim.lsp.buf.rename()<CR>
nnoremap ts <Cmd>lua vim.lsp.buf.code_action()<CR>
vnoremap ts <Cmd>lua vim.lsp.buf.code_action()<CR>
nnoremap tg <Cmd>Telescope lsp_workspace_symbols<CR>

nnoremap th <Cmd>Telescope lsp_document_symbols<CR> 
nnoremap tl <Cmd>Telescope treesitter<CR> 
nnoremap tm <Cmd>Telescope man_pages<CR> 
nnoremap tw <Cmd>Telescope keymaps<CR> 

nnoremap ty <Cmd>SignifyDiff<CR>
nnoremap tz <Cmd>Telescope git_status<CR>
nnoremap t, <Plug>(signify-prev-hunk)
nnoremap t. <Plug>(signify-next-hunk)
nnoremap tk <Cmd>Telescope git_commits<CR>

nnoremap tf <Cmd>lua require("dap").toggle_breakpoint()<CR>
nnoremap tv <Cmd>lua require("dap").step_over()<CR>
nnoremap tü <Cmd>lua require("dap").step_into()<CR>
nnoremap tä <Cmd>lua require("dap").continue()<CR>
nnoremap tö <Cmd>lua require("dap").terminate()<CR>

nnoremap <F1> <NOP>
inoremap <F1> <NOP>

" neovide
let g:neovide_refresh_rate = 60
let g:neovide_cursor_unfocused_outline_width = 0.05
let g:neovide_cursor_animation_length = 0.08
let g:neovide_cursor_vfx_mode = "pixiedust"
let g:neovide_cursor_vfx_particle_lifetime = 3.4
let g:neovide_cursor_vfx_particle_speed = 7
let g:neovide_cursor_vfx_particle_density = 0
let g:neovide_floating_blur_amount_x = 6.0
let g:neovide_floating_blur_amount_y = 6.0
let g:neovide_underline_automatic_scaling = v:true
let g:neovide_hide_mouse_when_typing = v:true

" rust
let g:rustfmt_autosave = 1
autocmd BufNewFile,BufRead *.rs set equalprg=rustfmt

" markdown
autocmd BufNewFile,BufRead *.md set tw=0 sw=2 ts=2 sts=0 et

" python
autocmd BufWritePost *.py,*.pyw call jobstart(["black", expand("%")], { "detach": v:false }) | set equalprg=black

" sql
autocmd BufNewFile,BufRead *.sql set sw=4 ts=4 sts=0 et

" kdl
autocmd BufNewFile,BufRead *.kdl set ft=kdl

" scm (treesitter queries)
autocmd BufNewFile,BufRead *.scm set ft=scm

" latex live preview (reimagined)
function LaunchZathura()
	" stop previously open zathura from "older" buffer
	call StopZathura()
	let g:zathura_id = jobstart(["zathura", expand("%:r") . ".pdf"], { "detach": v:true })
endfunction

function StopZathura()
	if exists("g:zathura_id")
		call jobstop(g:zathura_id)
	endif
endfunction

function RecompileLatex()
	silent update
	call jobstart(["pdflatex", "-halt-on-error", expand("%")], { "detach": v:true })
endfunction

autocmd BufNewFile,BufRead *.tex
  \	set filetype=latex sw=2 ts=2 sts=0 et
  \|nmap <Tab>1 <Cmd>call RecompileLatex()<CR>
  \|imap <Tab>1 <Cmd>call RecompileLatex()<CR>
  \|nmap <Tab>2 <Cmd>call LaunchZathura()<CR>
  \|imap <Tab>2 <Cmd>call LaunchZathura()<CR>
autocmd VimLeavePre *.tex
  \	call StopZathura()

" can't combine into one since update //might// write, but it doesn't have to
" (avoid recompiling unless truly needed, helps avoid CPU abuse and also
" flicker in zathura)
"autocmd CursorHold,CursorHoldI *.tex call RecompileIfModified()

" optional helper commands, if sensible for the current buffer
function AutoWriteToggle()
	augroup autowrite

		au!
		if exists("g:autowrite") && g:autowrite
			let g:autowrite = v:false
		else
			au CursorHold,CursorHoldI * silent update
			let g:autowrite = v:true
		endif

	augroup END
endfunction
command AutoWrite call AutoWriteToggle()
autocmd FocusGained * checktime


" some hi magic since base16's vim theme isn't quite there and I'm too lazy to
" change that
for level in ["Error", "Warn", "Info", "Hint"]
	for part in ["", "VirtualText", "Floating", "Sign"]
		execute "hi! Diagnostic" . part . level . " guifg=#001E1B"
	endfor
	execute "hi! DiagnosticUnderline" . level . " guisp=#003833 guibg=#003833"
endfor

lua <<EOF
require("nvim-treesitter.configs").setup {
	highlight = {
		enable = true,
	},

	playground = {
		enable = true,
	},
}

local cmp = require("cmp")
cmp.setup({
	sources = cmp.config.sources({
		{ name = "nvim_lsp" },
		{ name = "path" },
	}),
	mapping = {
		-- blatantly taken from https://github.com/hrsh7th/nvim-cmp/wiki/Example-mappings
		["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif vim.fn["vsnip#available"](1) == 1 then
        feedkey("<Plug>(vsnip-expand-or-jump)", "")
      else
        fallback()
      end
		end, { "i", "c", "s" }),

		["<S-Tab>"] = cmp.mapping(function()
      if cmp.visible() then
        cmp.select_prev_item()
      elseif vim.fn["vsnip#jumpable"](-1) == 1 then
        feedkey("<Plug>(vsnip-jump-prev)", "")
      end
    end, { "i", "c", "s" }),

		["<Enter>"] = cmp.mapping(cmp.mapping.confirm(), { "i", "c", "s" }),
	},
	snippet = {
		expand = function(args)
			vim.fn["vsnip#anonymous"](args.body)
		end
	},
})
cmp.setup.cmdline(":", {
	mapping = cmp.mapping.preset.cmdline(),
	sources = cmp.config.sources({
		{ name = "path" }
	}, {
		{ name = "cmdline" }
	})
})


local telescope = require("telescope")
telescope.setup({
	defaults = {
		layout_config = {
			horizontal = {
				prompt_position = "bottom",
				width = 0.91,
				height = 0.975,
			}
		}
	},
	extensions = {
		["ui-select"] = {
			require("telescope.themes").get_dropdown {}
		}
	},
})
telescope.load_extension("ui-select")

EOF

