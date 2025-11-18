-- options not already set in mini.basics

vim.o.complete = ".,w,b"
vim.o.completeopt = "menuone,noselect,fuzzy,nosort"
vim.o.expandtab = true
vim.o.laststatus = 3
vim.o.relativenumber = true
vim.o.updatetime = 250
vim.o.scrolloff = 8
vim.o.sidescrolloff = 8
vim.o.swapfile = false
vim.o.switchbuf = "usetab"
vim.o.tabstop = 2

vim.schedule(function() vim.o.clipboard = "unnamedplus" end)
