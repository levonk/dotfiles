-- Telescope config
local ok, telescope = pcall(require, 'telescope')
if not ok then return end

telescope.setup({
  defaults = {
    mappings = { i = { ['<C-u>'] = false, ['<C-d>'] = false } },
  },
  extensions = {
    fzf = {
      fuzzy = true,
      override_generic_sorter = true,
      override_file_sorter = true,
      case_mode = 'smart_case',
    },
  },
})

pcall(function() telescope.load_extension('fzf') end)
