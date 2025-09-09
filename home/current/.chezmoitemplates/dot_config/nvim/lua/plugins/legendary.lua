-- legendary.nvim
local ok, legendary = pcall(require, 'legendary')
if not ok then return end
legendary.setup({
  keymaps = {
    { '<C-g>', '<cmd>Telescope find_files<CR>', description = 'Telescope: Find Files' },
    { '<leader>fg', '<cmd>Telescope live_grep<CR>', description = 'Telescope: Find Text' },
    { '<leader>ff', '<cmd>Telescope current_buffer_fuzzy_find<CR>', description = 'Telescope: Find Text in Current Buffer' },
  },
})
