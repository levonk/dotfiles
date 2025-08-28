-- Core colors and theme
vim.o.termguicolors = true
-- Choose a default colorscheme if available
local colors = { 'tokyonight', 'catppuccin', 'habamax' }
for _, name in ipairs(colors) do
  local ok = pcall(vim.cmd.colorscheme, name)
  if ok then break end
end
