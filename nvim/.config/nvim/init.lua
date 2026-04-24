-- config for nvim 0.12 --

---------------------
------ Options ------
---------------------
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- UI
vim.o.number = true
vim.o.relativenumber = true
vim.o.cursorline = true
vim.o.signcolumn = "yes:1"
vim.o.wrap = false
vim.o.scrolloff = 8
vim.o.sidescrolloff = 8
vim.o.splitbelow = true
vim.o.splitright = true
vim.o.laststatus = 3
vim.o.breakindent = true
vim.o.linebreak = true
vim.o.diffopt = "internal,filler,closeoff,vertical"
vim.o.list = true
vim.o.listchars = "tab:» ,trail:·,extends:…,precedes:…"
vim.o.fillchars = "eob: "
vim.o.mouse = "a"

-- status line
vim.schedule(function()
  function _G.FileIcon()
    local ok, icons = pcall(require, "mini.icons")
    if not ok then
      return ""
    end
    return icons.get("filetype", vim.bo.filetype) or ""
  end

  function _G.GitBranch()
    local branch = vim.b.gitsigns_head
    if not branch or branch == "" then
      return ""
    end
    return "[" .. branch .. "]"
  end

  vim.o.statusline = "%{v:lua.FileIcon()} %f %m %= %{v:lua.GitBranch()} %l:%c"
end)

-- search
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.incsearch = true

-- indentation
vim.o.expandtab = true
vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.smartindent = true

-- completion
vim.o.autocomplete = true
vim.o.completeopt = "menuone,noselect,fuzzy"

-- timing
vim.o.updatetime = 250
vim.o.timeoutlen = 400

-- files / persistence
vim.o.undofile = true
vim.o.undodir = vim.fn.stdpath("state") .. "/undo"
-- vim.o.swapfile = true
vim.o.backup = false
vim.o.writebackup = false

-- system clipboard
vim.schedule(function() vim.o.clipboard = "unnamedplus" end)

-- splits keep context stable
vim.o.splitkeep = "screen"

-- floating windows / popup menu
vim.o.pumheight = 8
vim.o.pumblend = 5
vim.o.winblend = 5
vim.o.winborder = "single"

require("vim._core.ui2").enable()

vim.diagnostic.config({
  virtual_text = { current_line = true },
})

---------------------
------ Plugins ------
---------------------
vim.pack.add({
  "https://github.com/catppuccin/nvim",
  "https://github.com/nvim-mini/mini.nvim",
  "https://github.com/nvim-treesitter/nvim-treesitter",
  "https://github.com/nvim-treesitter/nvim-treesitter-textobjects",
  "https://github.com/mason-org/mason.nvim",
  "https://github.com/mason-org/mason-lspconfig.nvim",
  "https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim",
  "https://github.com/neovim/nvim-lspconfig",
  "https://github.com/ibhagwan/fzf-lua",
  "https://github.com/lewis6991/gitsigns.nvim",
  "https://github.com/nvim-lua/plenary.nvim",
  "https://github.com/NeogitOrg/neogit",
  "https://github.com/rcarriga/nvim-notify",
  "https://github.com/stevearc/conform.nvim",
  "https://github.com/MunifTanjim/nui.nvim",
  "https://github.com/nvim-neo-tree/neo-tree.nvim",
})

vim.cmd("packadd nvim.undotree")

require("catppuccin").setup({
  auto_integrations = true,
  no_italic = true,
  custom_highlights = function(colors)
    return {
      ["@type"] = { fg = colors.text },
      ["@type.builtin"] = { fg = colors.text },
      ["@module"] = { fg = colors.text },
    }
  end,
})
vim.cmd.colorscheme("catppuccin-macchiato")

require("mini.icons").setup()
MiniIcons.mock_nvim_web_devicons()
MiniIcons.tweak_lsp_kind()

require("mini.misc").setup()
MiniMisc.setup_auto_root()
MiniMisc.setup_restore_cursor()
MiniMisc.setup_termbg_sync()

require("mini.move").setup()
require("mini.pairs").setup()
require("mini.extra").setup()

local spec_ts = require("mini.ai").gen_spec.treesitter
require("mini.ai").setup({
  custom_textobjects = {
    f = spec_ts({ a = "@function.outer", i = "@function.inner" }),
    c = spec_ts({ a = "@class.outer", i = "@class.inner" }),
    a = spec_ts({ a = "@parameter.outer", i = "@parameter.inner" }),
  },
})

require("mini.surround").setup()
require("mini.bracketed").setup()
require("mini.cursorword").setup()

-- # treesitter
require("nvim-treesitter").install({
  "bash",
  "cpp",
  "css",
  "diff",
  "dockerfile",
  "gitignore",
  "go",
  "html",
  "java",
  "javascript",
  "json",
  "make",
  "python",
  "query",
  "regex",
  "ruby",
  "sql",
  "toml",
  "tsx",
  "typescript",
  "yaml",
})

require("nvim-treesitter-textobjects").setup({
  move = { set_jumps = true },
})

-- # LSPs
require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = { "cssls", "gopls", "jsonls", "pyrefly", "lua_ls", "ts_ls", "yamlls" },
})
require("mason-tool-installer").setup({
  ensure_installed = {
    "ruff",
    "stylua",
  },
})

require("conform").setup({
  formatters_by_ft = {
    python = { "ruff_fix", "ruff_format", "ruff_organize_imports" },
    lua = { "stylua" },
    go = { "gofmt" },
  },
  format_on_save = {
    timeout_ms = 500,
    lsp_format = "fallback",
  },
})

-- # fuzzy finder
require("fzf-lua").setup()

-- # git
require("gitsigns").setup()
require("neogit").setup()

-- nvim-notify
local notify = require("notify")
notify.setup({
  stages = "static",
  timeout = 2000,
  render = "wrapped-compact",
})
vim.notify = notify

-- neo-tree
require("neo-tree").setup({
  close_if_last_window = true,
  filesystem = {
    follow_current_file = { enabled = true },
    use_libuv_file_watcher = true,
  },
  event_handlers = {
    {
      event = "file_opened",
      handler = function() require("neo-tree.command").execute({ action = "close" }) end,
    },
  },
})

---------------------
------ Keymaps ------
---------------------
-- buffers
vim.keymap.set("n", "<leader>bd", "<cmd>bd<cr>", { desc = "Close buffer" })

-- finders and pickers
local fzf = require("fzf-lua")
vim.keymap.set("n", "<leader>ff", fzf.files, { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", fzf.live_grep, { desc = "Live grep" })
vim.keymap.set("n", "<leader>fb", fzf.buffers, { desc = "Buffers" })
vim.keymap.set("n", "<leader>f.", fzf.resume, { desc = "Resume" })
vim.keymap.set("n", "<leader>fs", fzf.lsp_document_symbols, { desc = "Document symbols" })
vim.keymap.set("n", "<leader><leader>", fzf.lsp_live_workspace_symbols, { desc = "Workspace symbols" })
vim.keymap.set("n", "<leader>fw", fzf.grep_cword, { desc = "Grep word" })

-- git
vim.keymap.set("n", "<leader>gg", "<cmd>Neogit<cr>", { desc = "Neogit" })
vim.keymap.set("n", "<leader>gc", "<cmd>Neogit commit<cr>", { desc = "Neogit commit" })
vim.keymap.set("n", "<leader>gb", function() require("gitsigns").blame() end, { desc = "Blame file" })

-- lsp
vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Definition" })
vim.keymap.set("n", "gD", vim.lsp.buf.declaration, { desc = "Declaration" })
vim.keymap.set("n", "gr", vim.lsp.buf.references, { desc = "References" })
vim.keymap.set("n", "gi", vim.lsp.buf.implementation, { desc = "Implementation" })
vim.keymap.set("n", "gy", vim.lsp.buf.type_definition, { desc = "Type definition" })
vim.keymap.set({ "n", "v" }, "<leader>cf", function() vim.lsp.buf.format({ async = true }) end, { desc = "Format" })

--navigation
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Window left" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Window down" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Window up" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Window right" })

--toggles
vim.keymap.set("n", "\\w", "<cmd>setlocal wrap!<cr>", { desc = "Toggle line wrap" })
vim.keymap.set("n", "\\u", "<cmd>Undotree<cr>", { desc = "Toggle Undotree" })
vim.keymap.set("n", "\\e", "<cmd>Neotree toggle<cr>", { desc = "Toggle file tree" })
vim.keymap.set("n", "\\b", function() require("gitsigns").blame_line({ full = true }) end, { desc = "Blame line popup" })
vim.keymap.set("n", "\\c", function() vim.lsp.codelens.enable(not vim.lsp.codelens.is_enabled()) end, { desc = "Toggle codelens" })

vim.keymap.set("n", "\\q", function()
  local wins = vim.fn.getqflist({ winid = 0 }).winid
  if wins ~= 0 then
    vim.cmd("cclose")
  else
    vim.cmd("copen")
  end
end, { desc = "Toggle quickfix" })

vim.keymap.set("n", "\\l", function()
  local list = vim.fn.getloclist(0)
  if #list == 0 then
    vim.notify("No location list", vim.log.levels.WARN)
    return
  end
  local wins = vim.fn.getloclist(0, { winid = 0 }).winid
  if wins ~= 0 then
    vim.cmd("lclose")
  else
    vim.cmd("lopen")
  end
end, { desc = "Toggle loclist" })

-- diagnostics
vim.keymap.set("n", "<leader>d", function() vim.diagnostic.setloclist({ open = true }) end)
vim.keymap.set("n", "]d", function() vim.diagnostic.jump({ count = 1, float = false }) end)
vim.keymap.set("n", "[d", function() vim.diagnostic.jump({ count = -1, float = false }) end)

-- treesitter
local move = require("nvim-treesitter-textobjects.move")
vim.keymap.set({ "n", "x", "o" }, "]m", function() move.goto_next_start("@function.outer", "textobjects") end)
vim.keymap.set({ "n", "x", "o" }, "[m", function() move.goto_previous_start("@function.outer", "textobjects") end)
vim.keymap.set({ "n", "x", "o" }, "]]", function() move.goto_next_start("@class.outer", "textobjects") end)
vim.keymap.set({ "n", "x", "o" }, "[[", function() move.goto_previous_start("@class.outer", "textobjects") end)

-- misc
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<cr>")
vim.keymap.set("n", "<leader>nh", require("notify").history, { desc = "Notification history" })
vim.keymap.set("n", "<leader>ud", function() vim.pack.update() end, { desc = "Update plugins" })

--------------------------
------ Autocommands ------
--------------------------
-- highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function() vim.highlight.on_yank() end,
})

-- autocomplete
vim.schedule(function()
  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client and client:supports_method("textDocument/completion") then
        vim.lsp.completion.enable(true, args.data.client_id, args.buf, { autotrigger = true })
      end
    end,
  })
end)

vim.api.nvim_create_autocmd("FileType", {
  callback = function() pcall(vim.treesitter.start) end,
})
