-- lspconfig servers and basic on_attach
local ok, lspconfig = pcall(require, 'lspconfig')
if not ok then return end

local capabilities = vim.lsp.protocol.make_client_capabilities()

local function on_attach(_, bufnr)
  local map = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
  end
  map('n', 'gd', vim.lsp.buf.definition, 'Goto definition')
  map('n', 'gr', vim.lsp.buf.references, 'References')
  map('n', 'K',  vim.lsp.buf.hover, 'Hover')
  map('n', '<leader>rn', vim.lsp.buf.rename, 'Rename')
  map('n', '<leader>ca', vim.lsp.buf.code_action, 'Code action')
end

local servers = { 'lua_ls', 'bashls', 'jsonls' }
for _, s in ipairs(servers) do
  lspconfig[s].setup({ on_attach = on_attach, capabilities = capabilities })
end
