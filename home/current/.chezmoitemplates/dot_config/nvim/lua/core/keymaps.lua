-- Core keymaps
local map = vim.keymap.set

map('n', '<leader>sv', '<cmd>vsplit<cr>', { desc = 'Split vertical' })
map('n', '<leader>sh', '<cmd>split<cr>',  { desc = 'Split horizontal' })
map('n', '<leader>q',  '<cmd>q<cr>',      { desc = 'Quit' })
map('n', '<leader>w',  '<cmd>w<cr>',      { desc = 'Write' })

-- Telescope bindings (if available)
map('n', '<leader>ff', function()
  pcall(require('telescope.builtin').find_files)
end, { desc = 'Find files' })
map('n', '<leader>fg', function()
  pcall(require('telescope.builtin').live_grep)
end, { desc = 'Live grep' })
map('n', '<leader>fb', function()
  pcall(require('telescope.builtin').buffers)
end, { desc = 'Buffers' })
map('n', '<leader>fh', function()
  pcall(require('telescope.builtin').help_tags)
end, { desc = 'Help tags' })
