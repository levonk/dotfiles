-- Mason + LSPConfig setup
local ok_mason, mason = pcall(require, 'mason')
if ok_mason then mason.setup() end

local ok_mlc, mlc = pcall(require, 'mason-lspconfig')
if ok_mlc then
  mlc.setup({ ensure_installed = { 'bashls', 'jsonls', 'lua_ls' } })
end

local ok_lsp, lspconfig = pcall(require, 'lspconfig')
if not ok_lsp then return end

-- Basic capabilities (no cmp here to keep minimal)
local capabilities = vim.lsp.protocol.make_client_capabilities()

-- Lua
lspconfig.lua_ls.setup({ capabilities = capabilities })
-- Bash
lspconfig.bashls.setup({ capabilities = capabilities })
-- JSON
lspconfig.jsonls.setup({ capabilities = capabilities })
