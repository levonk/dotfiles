-- mason-lspconfig
local ok, mlc = pcall(require, 'mason-lspconfig')
if not ok then return end
mlc.setup({ ensure_installed = { 'bashls', 'jsonls', 'lua_ls' } })
