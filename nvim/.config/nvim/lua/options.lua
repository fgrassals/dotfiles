-- options not already set in mini.basics

vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.o.complete = ".,w,b"
vim.o.completeopt = "menuone,noselect,fuzzy,nosort"
vim.o.expandtab = true
vim.o.laststatus = 3
vim.o.pumblend = 5
vim.o.relativenumber = true
vim.o.scrolloff = 8
vim.o.sidescrolloff = 8
vim.o.swapfile = false
vim.o.switchbuf = "usetab"
vim.o.tabstop = 2
vim.o.updatetime = 250
vim.o.winborder = "rounded"
vim.o.winblend = 4

vim.schedule(function() vim.o.clipboard = "unnamedplus" end)
