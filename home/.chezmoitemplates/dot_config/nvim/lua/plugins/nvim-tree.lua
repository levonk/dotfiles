-- nvim-tree.lua
local ok, nvimtree = pcall(require, 'nvim-tree')
if not ok then return end
nvimtree.setup({})
