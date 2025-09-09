-- Basic options shared across OS
local opt = vim.opt

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

opt.number = true
opt.relativenumber = true
opt.termguicolors = true
opt.mouse = 'a'
opt.clipboard = 'unnamedplus'
opt.swapfile = false
opt.backup = false
opt.undofile = true
opt.ignorecase = true
opt.smartcase = true
opt.updatetime = 300
opt.signcolumn = 'yes'
opt.splitright = true
opt.splitbelow = true
opt.scrolloff = 4
