-- lazy.nvim plugin specification
return {
  -- Core deps
  { 'nvim-lua/plenary.nvim' },

  -- LSP stack
  { 'williamboman/mason.nvim', config = function() pcall(require, 'lsp.mason') end },
  { 'williamboman/mason-lspconfig.nvim', config = function() pcall(require, 'lsp.mason_lspconfig') end },
  { 'neovim/nvim-lspconfig', config = function() pcall(require, 'lsp.lsp_config') end },
  { 'nvimdev/lspsaga.nvim', config = function() pcall(require, 'lsp.lspsaga') end },
  { 'hrsh7th/nvim-cmp', dependencies = {
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-path',
      'saadparwaiz1/cmp_luasnip',
      'L3MON4D3/LuaSnip',
    },
    config = function() pcall(require, 'lsp.cmp') end
  },

  -- Treesitter
  { 'nvim-treesitter/nvim-treesitter', build = ':TSUpdate', config = function() pcall(require, 'config.treesitter') end },
  { 'nvim-treesitter/nvim-treesitter-context', config = function() pcall(require, 'plugins.treesitter-context') end },

  -- Telescope
  { 'nvim-telescope/telescope.nvim', dependencies = { 'nvim-lua/plenary.nvim' }, config = function() pcall(require, 'config.telescope') end },
  {
    'nvim-telescope/telescope-fzf-native.nvim',
    build = 'make',
    cond = function() return vim.fn.executable('make') == 1 end,
    config = function()
      pcall(function() require('telescope').load_extension('fzf') end)
    end,
  },
  { 'nvim-telescope/telescope-project.nvim', config = function() pcall(require, 'plugins.project') end },

  -- UI/UX plugins per list
  { 'ggandor/leap.nvim', config = function() pcall(require, 'plugins.leap') end },
  { 'ggandor/flit.nvim', config = function() pcall(require, 'plugins.flit') end },
  { 'nvim-tree/nvim-tree.lua', config = function() pcall(require, 'plugins.nvim-tree') end },
  { 'nvim-lualine/lualine.nvim', config = function() pcall(require, 'plugins.lualine') end },
  { 'kylechui/nvim-surround', version = '*', config = function() pcall(require, 'plugins.nvim-surround') end },
  { 'romgrk/barbar.nvim', dependencies = { 'nvim-tree/nvim-web-devicons' }, init = function() vim.g.barbar_auto_setup = false end, config = function() pcall(require, 'plugins.barbar') end },
  { 'nvim-neo-tree/neo-tree.nvim', enabled = false }, -- prefer nvim-tree
  { 'nvim-tree/nvim-web-devicons' },
  { 'stevearc/dressing.nvim', config = function() pcall(require, 'plugins.dressing') end },
  { 'lewis6991/gitsigns.nvim', config = function() pcall(require, 'plugins.gitsigns') end },
  { 'sindrets/diffview.nvim', config = function() pcall(require, 'plugins.diffview') end },
  { 'cbochs/grapple.nvim', config = function() pcall(require, 'plugins.grapple') end },
  { 'mrjones2014/legendary.nvim', branch = 'master', config = function() pcall(require, 'plugins.legendary') end },
  { 'numToStr/Comment.nvim', config = function() pcall(require, 'plugins.Comment') end },
  { 'RRethy/vim-illuminate', config = function() pcall(require, 'plugins.illuminate') end },
  { 'karb94/neoscroll.nvim', config = function() pcall(require, 'plugins.neoscroll') end },
  { 'cbochs/portal.nvim', config = function() pcall(require, 'plugins.portal') end },

  -- Formatting/Linting (null-ls successor)
  { 'nvimtools/none-ls.nvim', config = function() pcall(require, 'lsp.null_ls') end },
}
