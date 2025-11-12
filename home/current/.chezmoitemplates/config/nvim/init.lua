-- Shared Neovim config (chezmoi template source)
-- Version guard with baseline for <0.8 and lazy.nvim for >=0.8

local has08 = 0
if vim and vim.fn and vim.fn.has then
  has08 = vim.fn.has("nvim-0.8")
end

-- Always load basic options and keymaps
pcall(require, "core.options")
pcall(require, "core.keymaps")
pcall(require, "core.autocmds")
pcall(require, "core.colors")

-- GUI/VSCode specific configs (vimscript block for parity with article)
vim.cmd([[
if exists('g:neovide')
  set guifont=JetBrainsMono\ Nerd\ Font:h10
  let g:neovide_scale_factor=1.0
  let g:neovide_cursor_animation_length=0
endif

if exists('g:vscode')
  nnoremap <silent> <C-g> <Cmd>call VSCodeCall('filesExplorer.findInFolder')<CR>
  nnoremap <silent> <leader>ff <Cmd>call VSCodeCall('actions.find')<CR>
  nnoremap <silent> <leader>fg <Cmd>call VSCodeCall('workbench.action.findInFiles')<CR>
  nnoremap <silent> <C-s> <Cmd>call VSCodeCall('workbench.action.files.save')<CR>
endif
]])

if has08 == 1 then
  -- Bootstrap lazy.nvim
  local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
  if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
      "git",
      "clone",
      "--filter=blob:none",
      "https://github.com/folke/lazy.nvim.git",
      "--branch=stable",
      lazypath,
    })
  end
  vim.opt.rtp:prepend(lazypath)

  -- Setup plugins
  local ok_lazy, lazy = pcall(require, "lazy")
  if ok_lazy then
    lazy.setup(require("config.plugins"), {})
  else
    vim.schedule(function()
      vim.notify("lazy.nvim failed to load", vim.log.levels.WARN)
    end)
  end

  -- Post-plugin configs (skip UI-heavy when in VSCode)
  if vim.g.vscode then
    -- VSCode-only minimal LSP if desired
    pcall(require, "lsp.mason")
    pcall(require, "lsp.mason_lspconfig")
    pcall(require, "lsp.lsp_config")
  else
    -- Full UI stack
    pcall(require, "lsp.mason")
    pcall(require, "lsp.mason_lspconfig")
    pcall(require, "lsp.lsp_config")
    pcall(require, "lsp.cmp")
    pcall(require, "lsp.lspsaga")
    pcall(require, "lsp.null_ls")
    pcall(require, "config.telescope")
    pcall(require, "config.treesitter")
    pcall(require, "plugins.treesitter-context")
    pcall(require, "plugins.project")
    pcall(require, "plugins.dressing")
    pcall(require, "plugins.legendary")
    pcall(require, "plugins.lualine")
    pcall(require, "plugins.nvim-tree")
    pcall(require, "plugins.barbar")
    pcall(require, "plugins.neoscroll")
    pcall(require, "plugins.portal")
    pcall(require, "plugins.leap")
    pcall(require, "plugins.flit")
    pcall(require, "plugins.nvim-surround")
    pcall(require, "plugins.Comment")
    pcall(require, "plugins.illuminate")
    pcall(require, "plugins.sidekick")
  end
else
  -- Minimal baseline on older Neovim
  vim.schedule(function()
    vim.notify("Running baseline config (Neovim < 0.8)", vim.log.levels.WARN)
  end)
end
