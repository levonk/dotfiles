-- lspsaga minimal setup
local ok, saga = pcall(require, 'lspsaga')
if not ok then return end
saga.setup({
  lightbulb = { enable = false },
})
