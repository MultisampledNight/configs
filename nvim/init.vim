call plug#begin("~/.local/share/nvim/vim-plug")

Plug 'MultisampledNight/colorschemes'

Plug 'hrsh7th/nvim-cmp'
Plug 'hrsh7th/vim-vsnip'
Plug 'hrsh7th/cmp-vsnip'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-nvim-lsp'

Plug 'neovim/nvim-lspconfig'

Plug 'mfussenegger/nvim-dap'
Plug 'rcarriga/nvim-dap-ui'

Plug 'DingDean/wgsl.vim'
Plug 'ap/vim-css-color'
Plug 'nvim-treesitter/nvim-treesitter'
Plug 'sheerun/vim-polyglot'

call plug#end()


" general settings
colorscheme base16-abnormalize-alt

set guifont=CamingoCode:h11
set termguicolors
set number
set noshowmode
set signcolumn=yes
set title
set titlestring=%m%h%w%F
set titlelen=0
set linebreak
set undofile

set autochdir
set clipboard+=unnamedplus
set completeopt=menu,menuone,preview,noselect
set mouse=a
set ignorecase
set smartcase
set scrolloff=2
set sidescrolloff=6

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

vnoremap <S-k> <Cmd>lua require("dapui").eval()<CR>
nnoremap tb <Cmd>lua require("dap").toggle_breakpoint()<CR>
nnoremap tc <Cmd>lua require("dap").continue()<CR>
nnoremap tt <Cmd>lua require("dap").step_over()<CR>
nnoremap ti <Cmd>lua require("dap").step_into()<CR>
nnoremap tq <Cmd>lua require("dap").terminate()<CR>

nnoremap <C-k> <Cmd>call jobstart(["term"], { "detach": v:true })<CR>

nnoremap <F1> <NOP>
inoremap <F1> <NOP>

" neovide
let g:neovide_refresh_rate = 60
let g:neovide_cursor_unfocused_outline_width = 0.05
let g:neovide_cursor_animation_length = 0.08
let g:neovide_cursor_vfx_mode = "pixiedust"
let g:neovide_cursor_vfx_particle_lifetime = 3.4
let g:neovide_cursor_vfx_particle_speed = 7
let g:neovide_cursor_vfx_particle_density = 18
let g:neovide_floating_blur_amount_x = 6.0
let g:neovide_floating_blur_amount_y = 6.0


" rust
let g:rustfmt_autosave = 1

" python
autocmd BufWritePost *.py,*.pyw call jobstart(["black", expand("%")], { "detach": v:false })

" latex live preview (reimagined)
autocmd BufRead *.tex set filetype=latex
autocmd BufWritePost *.tex call jobstart(["pdflatex", expand("%")], { "detach": v:true })

lua <<EOF
require("nvim-treesitter.configs").setup {
	highlight = {
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
		["<Tab>"] = cmp.mapping(cmp.mapping.select_next_item(), { "i", "c" }),
		["<A-Tab>"] = cmp.mapping(cmp.mapping.select_prev_item(), { "i", "c" }),
		["<Enter>"] = cmp.mapping(cmp.mapping.confirm(), { "i", "c" }),
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

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require("cmp_nvim_lsp").update_capabilities(capabilities)
local lspconfig = require("lspconfig")

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
	filetypes = {
		"rust",
		"netrw",
	},
	flags = {
		debounce_text_changes = 150,
	},
	handlers = {
		-- You may look at me, asking "but why would you do that"?
		-- For some reason, I think the diagnostics are overly intrusive and they effectively disturb me
		-- But other LSP features such as autocompletion are nice to have anyways
		["textDocument/publishDiagnostics"] = function(...) end
	},
}

local dap = require("dap")
local dapui = require("dapui")
dapui.setup({
	icons = { collapsed = "⮞", expanded = "⮟" },
	layouts = {
		{
			elements = {
				{ id = "breakpoints", size = 0.1 },
				{ id = "stacks", size = 0.25 },
				{ id = "watches", size = 0.1 },
				{ id = "scopes", size = 0.55 },
			},
			size = 42,
			position = "left",
		},
		{
			elements = {
				"repl",
				"console",
			},
			size = 6,
			position = "bottom",
		},
	},
})

dap.listeners.after.event_initialized["dapui_config"] = function()
	dapui.open()
end
dap.listeners.before.event_terminated["dapui_config"] = function()
	dapui.close()
end
dap.listeners.before.event_exited["dapui_config"] = function()
	dapui.close()
end

dap.adapters.python = {
	type = "executable";
	command = "python";
	args = { "-m", "debugpy.adapter" };
}
dap.configurations.python = {
	{
		type = "python";
		request = "launch";
		name = "Launch file";

		program = "${file}";
		pythonPath = "/usr/bin/python";
	},
}

local extension_path = vim.fn.expand "~/info/lurk/codelldb/extension/"
local codelldb_path = extension_path .. "adapter/codelldb"
local liblldb_path = extension_path .. "lldb/lib/liblldb.so"

dap.adapters.codelldb = function(callback, _)
  local stdout = vim.loop.new_pipe(false)
  local stderr = vim.loop.new_pipe(false)
  local handle
  local pid_or_err
  local port
  local error_message = ""

  local opts = {
    stdio = { nil, stdout, stderr },
    args = { "--liblldb", liblldb_path },
    detached = true,
  }

  handle, pid_or_err = vim.loop.spawn(codelldb_path, opts, function(code)
    stdout:close()
    stderr:close()
    handle:close()
    if code ~= 0 then
      print("codelldb exited with code", code)
      print("error message", error_message)
    end
  end)

  assert(handle, "Error running codelldb: " .. tostring(pid_or_err))

  stdout:read_start(function(err, chunk)
    assert(not err, err)
    if chunk then
      if not port then
        local chunks = {}
        for substring in chunk:gmatch "%S+" do
          table.insert(chunks, substring)
        end
        port = tonumber(chunks[#chunks])
        vim.schedule(function()
          callback {
            type = "server",
            host = "127.0.0.1",
            port = port,
          }
        end)
      else
        vim.schedule(function()
          require("dap.repl").append(chunk)
        end)
      end
    end
  end)
  stderr:read_start(function(_, chunk)
    if chunk then
      error_message = error_message .. chunk

      vim.schedule(function()
        require("dap.repl").append(chunk)
      end)
    end
  end)
end

dap.configurations.rust = {
  {
    name = "Launch file",
    type = "codelldb",
    request = "launch",
    program = function()
			local handle = io.popen("cargo exepath")
			local result = handle:read("*a")
			handle:close()
			return string.gsub(result, "[\n]+", "") 
		end,
		args = function()
			local args_iter = string.gmatch(vim.fn.input("launch args> ", "", "file"), "([^ ]+)")
			local args = {}

			for arg in args_iter do
				table.insert(args, arg)
			end

			return args
		end,
		cwd = "${workspaceFolder}",
  },
}
EOF

