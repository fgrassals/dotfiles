---------------------
------ Options ------
---------------------
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

require("vim._core.ui2").enable()


---------------------
------ Plugins ------
---------------------
vim.pack.add({
    "https://github.com/catppuccin/nvim",
    "https://github.com/nvim-mini/mini.nvim",
    "https://github.com/nvim-treesitter/nvim-treesitter",
    "https://github.com/nvim-treesitter/nvim-treesitter-textobjects",
})

vim.cmd.colorscheme("catppuccin-macchiato")

-- # mini.nvim
require("mini.basics").setup({
  options = { extra_ui = true },
  mappings = {
    basic = false,
    windows = true,
    move_with_alt = true,
  },
})

require("mini.icons").setup()
MiniIcons.mock_nvim_web_devicons()
MiniIcons.tweak_lsp_kind()

-- require("mini.statusline").setup()

require("mini.misc").setup()
MiniMisc.setup_auto_root()
MiniMisc.setup_restore_cursor()
MiniMisc.setup_termbg_sync()

require("mini.move").setup()
require("mini.pairs").setup()
require("mini.extra").setup()

spec_ts = require("mini.ai").gen_spec.treesitter
require("mini.ai").setup({
  custom_textobjects = {
    f = spec_ts({ a = "@function.outer", i = "@function.inner" }),
    c = spec_ts({ a = "@class.outer", i = "@class.inner" }),
    a = spec_ts({ a = "@parameter.outer", i = "@parameter.inner" }),
  }
})

-- require("mini.surround").setup()
require("mini.bracketed").setup()
require("mini.cursorword").setup()

-- TODO: setup completion

-- # treesitter
require("nvim-treesitter").install({ "bash", "cpp", "css", "diff", "dockerfile", "gitignore", "go", "html", "html_tags", "java", "javascript", "json", "jsx", "make", "markdown", "markdown_inline", "python","query","regex", "ruby", "sql", "toml", "tsx", "typescript", "yaml"})
vim.api.nvim_create_autocmd("FileType", {
  callback = function() pcall(vim.treesitter.start) end
})

require("nvim-treesitter-textobjects").setup({
  move = { set_jumps = true },
})

---------------------
------ Keymaps ------
---------------------


--------------------------
------ Autocommands ------
--------------------------
