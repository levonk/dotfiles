-- vim-illuminate
local ok, illuminate = pcall(require, 'illuminate')
if not ok then return end
illuminate.configure({
  delay = 200,
  modes_denylist = { 'v', 'V', '\22' },
})
