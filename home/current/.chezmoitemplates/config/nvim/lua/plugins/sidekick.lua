-- sidekick.nvim
local ok, sidekick = pcall(require, 'sidekick')
if not ok then return end

sidekick.setup({
  -- Default configuration
  -- Sidekick will automatically show relevant information in a sidebar
  -- You can customize this based on your preferences
})
