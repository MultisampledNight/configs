" File: lspconfigfun.vim
" Author: MultisampledNight (multisn8)

lua <<EOF
require'lspconfig'.rust_analyzer.setup({})
require'lspconfig'.texlab.setup({})
require'lsp_signature'.on_attach()
EOF
