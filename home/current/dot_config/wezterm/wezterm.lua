-- WezTerm configuration
local wezterm = require 'wezterm'
return {
  font = wezterm.font_with_fallback({
    { family = 'JetBrainsMono Nerd Font Mono' },
    { family = 'JetBrainsMono Nerd Font' },
  }),
  font_size = 12.5,
}
