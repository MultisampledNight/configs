function ProjectToplevel()
  " is this a rust project?
  let toplevel = trim(system("cargo metadata --format-version=1 --offline --no-deps 2>/dev/null"))
  if v:shell_error == 0
    return json_decode(toplevel)["workspace_root"]
  endif

  " nope, is this a git repo?
  let toplevel = trim(system("git rev-parse --show-toplevel"))
  if v:shell_error == 0
    return toplevel
  endif

  " nope, fall back to the cwd
  return getcwd()
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
  hi! SignColumn ctermbg=black

  hi! LineNr ctermfg=grey
  hi! StatusLine ctermfg=blue ctermbg=black
  hi! StatusLineNC ctermfg=grey ctermbg=black

  nnoremap <A-S-j> <Cmd>2split<CR>z2<CR><Cmd>term i3status<CR><Cmd>set nonumber<CR>G<C-w>j

  nnoremap <A-S-f> <Cmd>silent !brightnessctl --exponent set 5\%-<CR>
  nnoremap <A-S-v> <Cmd>silent !brightnessctl --exponent set 3\%+<CR>
else
  colorscheme base16-abnormalize-alt
  set termguicolors

  set winblend=50
  set pumblend=50

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
  lspconfig.tsserver.setup {}

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

set guifont=IBM_Plex_Mono:h14:#h-slight
set linespace=2
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

function TelescopeOnToplevel(command)
  silent update
  exe "Telescope " . a:command . " cwd=" . ProjectToplevel()
endfunction

function CreateNewFile()
  let sub_path = trim(input("New file name: ", expand("<cword>"), "file"))
  if sub_path == ""
    return
  endif

  let full_path = expand("%:p:h") . "/" . sub_path
  call mkdir(fnamemodify(full_path, ":h"), "p")
  exe "edit " . full_path
  write
endfunction

nnoremap tt <Cmd>Telescope resume<CR>
nnoremap ti <Cmd>call TelescopeOnToplevel("find_files")<CR>
nnoremap te <Cmd>call TelescopeOnToplevel("live_grep")<CR> 
nnoremap td <Cmd>call TelescopeOnToplevel("lsp_definitions")<CR>
nnoremap tu <Cmd>call TelescopeOnToplevel("lsp_references")<CR>
nnoremap ta <Cmd>call TelescopeOnToplevel("lsp_implementations")<CR>

nnoremap to <Cmd>TroubleToggle<CR>
nnoremap tb <Cmd>update \| Trouble<CR>

nnoremap tn <Cmd>update \| lua vim.lsp.buf.hover()<CR>
nnoremap tr <Cmd>update \| lua vim.lsp.buf.rename()<CR>
nnoremap ts <Cmd>update \| lua vim.lsp.buf.code_action()<CR>
vnoremap ts <Cmd>update \| lua vim.lsp.buf.code_action()<CR>
nnoremap tg <Cmd>call TelescopeOnToplevel("lsp_workspace_symbols")<CR>

nnoremap th <Cmd>call TelescopeOnToplevel("lsp_document_symbols")<CR>
nnoremap tl <Cmd>call TelescopeOnToplevel("treesitter")<CR>
nnoremap tm <Cmd>call TelescopeOnToplevel("man_pages")<CR>
nnoremap tw <Cmd>call TelescopeOnToplevel("keymaps")<CR>

nnoremap ty <Cmd>SignifyDiff<CR>
nnoremap tz <Cmd>call TelescopeOnToplevel("git_status")<CR>
nnoremap t, <Plug>(signify-prev-hunk)
nnoremap t. <Plug>(signify-next-hunk)
nnoremap tk <Cmd>call CreateNewFile()<CR>

nnoremap tq <Cmd>update \| call jobstart("cargo fmt")<CR>

nnoremap tf <Cmd>lua require("dap").toggle_breakpoint()<CR>
nnoremap tv <Cmd>lua require("dap").step_over()<CR>
nnoremap tü <Cmd>lua require("dap").step_into()<CR>
nnoremap tä <Cmd>lua require("dap").continue()<CR>
nnoremap tö <Cmd>lua require("dap").terminate()<CR>

nnoremap <F1> <NOP>
inoremap <F1> <NOP>

" neovide
let g:neovide_refresh_rate = 60
let g:neovide_refresh_rate_idle = 5
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

" global
" hacky and bound to interfere with the latex or typst machinery, but it works
function CdProjectToplevel(_timer_id)
  exe "tcd " . ProjectToplevel()
endfunction
autocmd BufEnter * call timer_start(50, "CdProjectToplevel")

" rust
autocmd BufNewFile,BufRead *.rs set equalprg=rustfmt formatprg=rustfmt

" markdown
autocmd BufNewFile,BufRead *.md set tw=0 sw=2 ts=2 sts=0 et

" python
autocmd BufWritePost *.py,*.pyw call jobstart(["black", expand("%")], { "detach": v:false })

" sql
autocmd BufNewFile,BufRead *.sql set sw=4 ts=4 sts=0 et

" kdl
autocmd BufNewFile,BufRead *.kdl set ft=kdl

" scm (treesitter queries)
autocmd BufNewFile,BufRead *.scm set ft=scm

" latex
autocmd BufNewFile,BufRead *.tex
  \ set filetype=latex sw=2 ts=2 sts=0 et
  \|noremap <buffer> <Leader>1 <Cmd>call ExecAtFile(["pdflatex", "-halt-on-error", expand("%")])<CR>
  \|noremap <buffer> <Leader>2 <Cmd>call ViewCurrentPdf()<CR>
autocmd VimLeavePre *.tex
  \ call StopProgram("zathura")

" typst
autocmd BufNewFile,BufRead *.typ
  \ set filetype=text sw=2 ts=2 sts=0 et
  \|call LaunchProgram("typst" . bufnr(), ["typst", "watch", expand("%:p")])
  \|noremap <buffer> <Leader>2 <Cmd>call ViewCurrentPdf()<CR>
autocmd VimLeavePre *.typ
  \ call StopProgram("typst" . bufnr())
  \|call StopProgram("zathura")

" both latex and typst, and anything that would require a pdf
autocmd BufEnter *.tex,*.typ call ViewCurrentPdf()
let g:tracked_programs = {}

function CurrentPdfPath()
  return expand("%:p:r") . ".pdf"
endfunction

function ViewCurrentPdf()
  if !has_key(g:tracked_programs, "zathura")
    call LaunchProgram("zathura", ["zathura", CurrentPdfPath()])
    return
  endif

  try
    let pid = jobpid(g:tracked_programs["zathura"])
  catch /.*E900: Invalid channel id/
    call LaunchProgram("zathura", ["zathura", CurrentPdfPath()])
    return
  endtry

  let command = [
        \ "dbus-send",
        \ "--type=method_call",
        \ "--dest=org.pwmt.zathura.PID-" . pid,
        \ "/org/pwmt/zathura",
        \ "org.pwmt.zathura.OpenDocument",
        \ 'string:' . CurrentPdfPath() . '',
        \ "string:",
        \ "int32:",
  \ ]
  call ExecAtFile(command)
endfunction

function LaunchProgram(name, command)
  " stop previously open from "older" buffer
  call StopProgram(a:name)
  let g:tracked_programs[a:name] = ExecAtFile(a:command)
endfunction

function StopProgram(name)
  if has_key(g:tracked_programs, a:name)
    call jobstop(g:tracked_programs[a:name])
    unlet g:tracked_programs[a:name]
  endif
endfunction

function ExecAtFile(command)
  silent update

  exe "lcd " . expand("%:p:h")
  let job_id = jobstart(a:command, { "detach": v:true })
  lcd -

  return job_id
endfunction

" optional helper commands, if sensible for the current buffer
function AutoWriteToggle()
  augroup autowrite

    au!
    if exists("g:autowrite") && g:autowrite
      let g:autowrite = v:false
    else
      au CursorHold,CursorHoldI * call UpdateIfPossible()
      let g:autowrite = v:true
    endif

  augroup END
endfunction

function UpdateIfPossible()
  if &buftype == ""
    silent update
  endif
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

local feedkey = function(key, mode)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, true, true), mode, true)
end

local cmp = require("cmp")

local function next_item(fallback)
  if cmp.visible() then
    cmp.select_next_item()
  else
    fallback()
  end
end

local function prev_item(fallback)
  if cmp.visible() then
    cmp.select_prev_item()
  else
    fallback()
  end
end

cmp.setup({
  sources = cmp.config.sources({
    { name = "nvim_lsp" },
    { name = "vsnip" },
    { name = "path" },
  }),
  snippet = {
    expand = function(args)
      vim.fn["vsnip#anonymous"](args.body)
    end,
  },
  mapping = {
    ["<S-Tab>"] = cmp.mapping(prev_item, { "i", "c", "s" }),

    ["<Tab>"] = cmp.mapping(next_item, { "i", "c", "s" }),

    ["<Enter>"] = cmp.mapping(
      cmp.mapping.confirm({
        behavior = cmp.ConfirmBehavior.Replace,
      }),
      { "i", "c", "s" }
    ),
  },
  window = {
    completion = {
      scrollbar = false,
    },
    documentation = cmp.config.disable,
  },
  experimental = {
    ghost_text = true,
  },
})
cmp.setup.cmdline(":", {
  mapping = cmp.mapping.preset.cmdline(),
  sources = cmp.config.sources({
    { name = "cmdline" }
  })
})

local telescope = require("telescope")
telescope.setup({
  defaults = {
    winblend = 50,
    layout_config = {
      horizontal = {
        prompt_position = "bottom",
        width = 0.91,
        height = 0.975,
      },
    },
  },
  extensions = {
    ["ui-select"] = {
      require("telescope.themes").get_dropdown {}
    },
  },
})
telescope.load_extension("ui-select")

EOF

" vim: sw=2 ts=2 et
