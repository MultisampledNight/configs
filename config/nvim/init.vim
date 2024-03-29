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
colorscheme base16-abnormalize-alt
set termguicolors

if exists("g:neovide")
  set winblend=80
  set pumblend=30
else
  set winblend=10
  set pumblend=10
endif

set guifont=JetBrainsMonoNL_NF_Light:h14
set linespace=4
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

nnoremap <A-S-j> <Cmd>2split<CR>z2<CR><Cmd>term i3status<CR><Cmd>set nonumber<CR>G<C-w>j
nnoremap <A-S-f> <Cmd>silent !brightnessctl --exponent set 5\%-<CR>
nnoremap <A-S-v> <Cmd>silent !brightnessctl --exponent set 3\%+<CR>

function TelescopeOnToplevel(command)
  silent update
  exe "Telescope " . a:command . " cwd=" . ProjectToplevel()
endfunction

function CreateNewFile()
  let sub_path = trim(input("New file name: ", expand("<cword>")))
  if sub_path == ""
    return
  endif

  let full_path = expand("%:.:h") . "/" . sub_path
  call mkdir(fnamemodify(full_path, ":h"), "p")
  exe "edit " . full_path
  write
endfunction

function RenameCurrentFile()
  let old = expand("%:t")
  let sub_path = trim(input("Rename to: ", old))
  if sub_path == ""
    return
  elseif sub_path == old
    echo "Already named that way"
    return
  endif

  let full_path = expand("%:.:h") . "/" . sub_path
  call mkdir(fnamemodify(full_path, ":h"), "p")
  exe "saveas " . full_path

  exe "silent !rm " . old
endfunction

nnoremap <Space><Space> <Cmd>Telescope resume<CR>
nnoremap <Space>f <Cmd>call TelescopeOnToplevel("find_files follow=true")<CR>
nnoremap <Space>/ <Cmd>call TelescopeOnToplevel("live_grep")<CR> 
nnoremap gd <Cmd>call TelescopeOnToplevel("lsp_definitions")<CR>
nnoremap gu <Cmd>call TelescopeOnToplevel("lsp_references")<CR>
nnoremap <Space>i <Cmd>call TelescopeOnToplevel("lsp_implementations")<CR>

nnoremap <Space>o <Cmd>TroubleToggle<CR>
nnoremap <Space>b <Cmd>update \| Trouble<CR>

nnoremap <Space>n <Cmd>update \| lua if require("dap").session() == nil then vim.lsp.buf.hover() else require("dap.ui.widgets").hover() end<CR>
vnoremap <Space>n <Cmd>update \| lua if require("dap").session() == nil then vim.lsp.buf.hover() else require("dap.ui.widgets").hover() end<CR>
nnoremap <Space>r <Cmd>update \| lua vim.lsp.buf.rename()<CR>
nnoremap <Space>a <Cmd>update \| lua vim.lsp.buf.code_action()<CR>
vnoremap <Space>a <Cmd>update \| lua vim.lsp.buf.code_action()<CR>
nnoremap <Space>g <Cmd>call TelescopeOnToplevel("lsp_workspace_symbols")<CR>

nnoremap <Space>s <Cmd>call TelescopeOnToplevel("lsp_document_symbols")<CR>
nnoremap <Space>l <Cmd>call TelescopeOnToplevel("treesitter")<CR>
nnoremap <Space>m <Cmd>call TelescopeOnToplevel("man_pages")<CR>
nnoremap <Space>w <Cmd>call TelescopeOnToplevel("keymaps")<CR>

nnoremap <Space>. <Cmd>call TelescopeOnToplevel("git_status")<CR>
nnoremap <Space>j <Cmd>call CreateNewFile()<CR>
nnoremap <Space>c <Cmd>call RenameCurrentFile()<CR>

nnoremap <Space>q <Cmd>update \| call jobstart("cargo fmt")<CR>

nnoremap <Space>z <Cmd>lua require("dap").toggle_breakpoint()<CR>
nnoremap <Space>v <Cmd>lua require("dap").step_over()<CR>
nnoremap <Space>ü <Cmd>lua require("dap").step_into()<CR>
nnoremap <Space>ä <Cmd>lua require("dap").step_out()<CR>
nnoremap <Space>ö <Cmd>lua require("dap").continue()<CR>
nnoremap <Space>y <Cmd>lua require("dap").terminate()<CR>
nnoremap <Space>k <Cmd>lua require("dapui").toggle()<CR>

nnoremap <F1> <NOP>
inoremap <F1> <NOP>

" neovide
let g:neovide_refresh_rate = 60
let g:neovide_refresh_rate_idle = 5
let g:neovide_cursor_unfocused_outline_width = 0.025
let g:neovide_cursor_animation_length = 0.08
let g:neovide_floating_blur_amount_x = 16.0
let g:neovide_floating_blur_amount_y = 16.0
let g:neovide_floating_shadow = v:true
let g:neovide_light_angle_degrees = 40
let g:neovide_light_radius = 10
let g:neovide_underline_automatic_scaling = v:true
let g:neovide_hide_mouse_when_typing = v:true

if hostname() == "elusive"
  let g:neovide_mouse_as_touch = v:true
endif

" global
AutoWrite
" hacky and bound to interfere with the latex or typst machinery, but it works
function CdProjectToplevel(_timer_id)
  exe "tcd " . ProjectToplevel()
endfunction
autocmd BufEnter * call timer_start(50, "CdProjectToplevel")

" godot
function CloseIfAlreadyOpen()
  let pidfile = "~/zukunftslosigkeit/state/neovim/editing-in-godot"
  call system("ps -p $(cat " . pidfile . ")")
  if v:shell_error == 0
    " yep, already editing
    exit
  endif

  " oh well then let's propagate that we're currently editing
  call system("mkdir $(dirname " . pidfile . ")")
  call system("echo -n " . getpid() . " > " . pidfile)
endfunction
autocmd VimEnter *.gd
  \ call CloseIfAlreadyOpen()
autocmd BufNewFile,BufRead *.gd
  \ set filetype=gdscript
  \|set updatetime=500

" rust
autocmd BufNewFile,BufRead *.rs set equalprg=rustfmt formatprg=rustfmt
autocmd BufNewFile,BufRead *.rs lua require("dap.ext.vscode").load_launchjs(".ide/launch.json")
function RustProjectExecutable()
  let metadata = trim(system("cargo metadata --format-version=1 --offline --no-deps 2>/dev/null"))
  if metadata == ""
    return
  endif
  let metadata = json_decode(metadata)
  let executable = metadata["target_directory"]
    \ . "/debug/"
    \ . metadata["packages"][0]["name"]
  return executable
endfunction

" markdown
autocmd BufNewFile,BufRead *.md set tw=0 sw=2 ts=2 sts=0 et

" agda
autocmd BufNewFile,BufRead *.agda set ft=agda

" python
autocmd BufWritePost *.py,*.pyw call jobstart(["black", expand("%")], { "detach": v:false })

" sql
autocmd BufNewFile,BufRead *.sql set sw=4 ts=4 sts=0 et

" kdl
autocmd BufNewFile,BufRead *.kdl set ft=kdl

" scm (treesitter queries)
autocmd BufNewFile,BufRead *.scm set ft=scm

" html
autocmd BufNewFile,BufRead *.html set ts=2 sw=2 noet

" latex
autocmd BufNewFile,BufRead *.tex
  \ set filetype=latex sw=2 ts=2 sts=0 et
  \|noremap <buffer> <Leader>1 <Cmd>call ExecAtFile(["pdflatex", "-halt-on-error", expand("%")])<CR>
  \|noremap <buffer> <Leader>2 <Cmd>call ViewCurrentPdf()<CR>
autocmd VimLeavePre *.tex
  \ call StopProgram("evince")

" typst
autocmd BufNewFile,BufRead *.typ
  \ set filetype=typst sw=2 ts=2 sts=0 et
  \|call LaunchProgram("typst" . bufnr(), ["typst", "watch", expand("%:p")])
  \|noremap <buffer> <Leader>2 <Cmd>call ViewCurrentPdf()<CR>
autocmd VimLeavePre *.typ
  \ call StopProgram("typst" . bufnr())
  \|call StopProgram("evince")

" both latex and typst, and anything that would require a pdf
autocmd BufEnter *.tex,*.typ call ViewCurrentPdf()
let g:tracked_programs = {}

function CurrentPdfPath()
  return expand("%:p:r") . ".pdf"
endfunction

function ViewCurrentPdf()
  if !has_key(g:tracked_programs, "evince")
    echo CurrentPdfPath()
    call LaunchProgram("evince", ["evince", CurrentPdfPath()])
    return
  endif

  try
    let pid = jobpid(g:tracked_programs["evince"])
  catch /.*E900: Invalid channel id/
    call LaunchProgram("evince", ["evince", CurrentPdfPath()])
    return
  endtry
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

lspconfig.gdscript.setup {}
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
lspconfig.typst_lsp.setup {}

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

require("nvim-treesitter.configs").setup {
  highlight = {
    enable = true,
  },
  indent = {
    enable = true,
  },

  playground = {
    enable = true,
  },
}

require("treesitter-context").setup {
  max_lines = 4,
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
    vimgrep_arguments = {
      "rg",
      "--color=never",
      "--no-heading",
      "--with-filename",
      "--line-number",
      "--column",
      "--smart-case",
      "--follow",
    },
    winblend = vim.o.winblend,
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

-- https://github.com/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation#ccrust-via-lldb-vscode
local dap = require("dap")
dap.adapters.lldb = {
  type = "executable",
  command = "/usr/bin/env",
  args = { "lldb-vscode" },
  name = "lldb",
}
dap.configurations.rust = {
  {
    name = "Launch",
    type = "lldb",
    request = "launch",
    program = vim.fn.RustProjectExecutable(),
    cwd = "${workspaceFolder}",
    stopOnEntry = false,

    initCommands = function()
      -- Find out where to look for the pretty printer Python module
      local rustc_sysroot = vim.fn.trim(vim.fn.system("rustc --print sysroot"))

      local script_import = 'command script import "' .. rustc_sysroot .. '/lib/rustlib/etc/lldb_lookup.py"'
      local commands_file = rustc_sysroot .. "/lib/rustlib/etc/lldb_commands"

      local commands = {}
      local file = io.open(commands_file, "r")
      if file then
        for line in file:lines() do
          table.insert(commands, line)
        end
        file:close()
      end
      table.insert(commands, 1, script_import)

      return commands
    end,
  },
}

local dapui = require("dapui")
dapui.setup()

-- taken from https://github.com/rcarriga/nvim-dap-ui/
dap.listeners.after.event_initialized["dapui_config"] = function()
  dapui.open()
end
-- dap.listeners.before.event_terminated["dapui_config"] = function()
--   dapui.close()
-- end
-- dap.listeners.before.event_exited["dapui_config"] = function()
--   dapui.close()
-- end

EOF

" vim: sw=2 ts=2 et
