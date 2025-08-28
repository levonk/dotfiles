-- Core autocmds
local aug = vim.api.nvim_create_augroup('UserCore', { clear = true })

vim.api.nvim_create_autocmd('TextYankPost', {
  group = aug,
  callback = function()
    pcall(vim.highlight.on_yank, { higroup = 'IncSearch', timeout = 150 })
  end,
})
