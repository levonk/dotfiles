-- telescope-project
local ok, telescope = pcall(require, 'telescope')
if not ok then return end
pcall(telescope.load_extension, 'project')
