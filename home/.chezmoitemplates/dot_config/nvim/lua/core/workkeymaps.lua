-- Optional extra keymaps for work context
-- Add org- or project-specific keymaps here.
-- Example: map <leader>gd to diffview if available
local map = vim.keymap.set
map('n', '<leader>gd', function()
  pcall(vim.cmd, 'DiffviewOpen')
end, { desc = 'Diffview open' })
