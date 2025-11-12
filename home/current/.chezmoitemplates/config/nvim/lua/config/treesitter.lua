-- Treesitter config
local ok, ts = pcall(require, 'nvim-treesitter.configs')
if not ok then return end

-- Set install preferences before setup
pcall(function()
  require('nvim-treesitter.install').compilers = { 'clang' }
  require('nvim-treesitter.install').prefer_git = true
end)

ts.setup({
  ensure_installed = 'all',
  sync_install = true,
  highlight = { enable = true },
  indent = { enable = true },
})
