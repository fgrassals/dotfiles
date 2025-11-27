-- general plugin configuration
-- vim: foldmethod=marker foldlevel=0

local now = MiniDeps.now
local later = MiniDeps.later
local add = MiniDeps.add

-- run now if nvim was started with args, else later
local now_if_args = vim.fn.argc(-1) > 0 and now or later

-- {{{ colorschemes
now(function()
  add({ source = "catppuccin/nvim", name = "catppuccin" })

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

  vim.cmd("colorscheme catppuccin-macchiato")
end)
-- }}}

-- {{{ mini.nvim
now(
  function()
    require("mini.basics").setup({
      options = {
        extra_ui = true,
      },
      mappings = {
        basic = false,
        windows = true,
        move_with_alt = true,
      },
    })
  end
)

now(function()
  require("mini.icons").setup()
  now_if_args(MiniIcons.mock_nvim_web_devicons)
  now_if_args(MiniIcons.tweak_lsp_kind)
end)

now_if_args(function()
  require("mini.misc").setup()

  MiniMisc.setup_auto_root()
  MiniMisc.setup_restore_cursor()
  MiniMisc.setup_termbg_sync()
end)

now(function() require("mini.sessions").setup() end)

now(function()
  local header = [[
  ░▄▀▄░█░█░█▀▀░░░▀█▀░█▀▀░█▀█░█▀▀░█▄█░█▀█░█▀▀░▀▀█
  ░█\█░█░█░█▀▀░░░░█░░█▀▀░█░█░█▀▀░█░█░█░█░▀▀█░░▀░
  ░░▀\░▀▀▀░▀▀▀░░░░▀░░▀▀▀░▀░▀░▀▀▀░▀░▀░▀▀▀░▀▀▀░░▀░
  ]]

  local starter = require("mini.starter")
  starter.setup({
    header = header,
  })

  -- todo add startup time to the footer
end)

now(function()
  require("mini.statusline").setup({
    use_icons = true,
    content = {
      active = function()
        local s = MiniStatusline

        -- left side
        local mode, mode_hl = s.section_mode({ trunc_width = 120 })

        local head = vim.b.gitsigns_head
        local branch = (head and head ~= "") and (" " .. head) or ""
        local branch_hl = "MiniStatuslineDevinfo"

        local filename = vim.bo.buftype ~= "terminal" and "%f%m%r" or "%t"
        local filename_hl = "MiniStatuslineFilename"

        -- right side

        -- diagnostics
        local E, W, I, H = vim.diagnostic.severity.ERROR, vim.diagnostic.severity.WARN, vim.diagnostic.severity.INFO, vim.diagnostic.severity.HINT
        local counts = {
          [E] = #vim.diagnostic.get(0, { severity = E }),
          [W] = #vim.diagnostic.get(0, { severity = W }),
          [I] = #vim.diagnostic.get(0, { severity = I }),
          [H] = #vim.diagnostic.get(0, { severity = H }),
        }
        local diag_groups = {}
        local function push(hl, str) table.insert(diag_groups, ("%%#%s#%s"):format(hl, str)) end
        if counts[E] > 0 then
          push("DiagnosticError", ("󰅚 %d"):format(counts[E]))
        end
        if counts[W] > 0 then
          push("DiagnosticWarn", ("󰀪 %d"):format(counts[W]))
        end
        if counts[I] > 0 then
          push("DiagnosticInfo", ("󰋽 %d"):format(counts[I]))
        end
        if counts[H] > 0 then
          push("DiagnosticHint", ("󰌶 %d"):format(counts[H]))
        end

        -- file type
        local file_type = vim.bo.filetype ~= "" and vim.bo.filetype or ""
        local file_icon = ""
        local found, mini_icons = pcall(require, "mini.icons")
        if found and mini_icons.get then
          local got = mini_icons.get("filetype", file_type)
          file_icon = (type(got) == "table") and (got[1] or "") or (got or "")
        end

        local ft = file_icon ~= "" and (file_icon .. " " .. file_type) or file_type

        -- file info
        local encoding = vim.bo.fileencoding ~= "" and vim.bo.fileencoding or vim.o.encoding
        local ff_map = { unix = "lf", mac = "cr", dos = "crlf" }
        local file_format = ff_map[vim.bo.fileformat] or vim.bo.fileformat
        local file_info = string.format("%s[%s]", encoding, file_format)

        -- loaction in buf
        local location = string.format("%d:%d", vim.fn.line("."), vim.fn.col("."))

        return s.combine_groups({
          { hl = mode_hl, strings = { mode } },
          { hl = branch_hl, strings = { branch } },
          { hl = filename_hl, strings = { filename } },
          "%=", -- spacer
          { hl = "", strings = { table.concat(diag_groups, " ") } },
          { hl = filename_hl, strings = { location } },
          { hl = filename_hl, strings = { ft } },
          { hl = filename_hl, strings = { file_info } },
        })
      end,
    },
  })
end)

later(function() require("mini.extra").setup() end)
later(function() require("mini.ai").setup() end)
-- later(function() require("mini.surround").setup() end)
later(function() require("mini.bracketed").setup() end)

later(function()
  -- no text suggestions and snippets last
  local process_items = function(items, base)
    return MiniCompletion.default_process_items(items, base, {
      kind_priority = { Text = -1, Snippet = 99 },
    })
  end

  require("mini.completion").setup({
    lsp_completion = {
      source_func = "omnifunc",
      auto_setup = false,
      process_items = process_items,
    },
  })

  -- setup omnifunc on lsp attach only
  vim.api.nvim_create_autocmd("LspAttach", {
    group = _G.fgconf.augroup,
    callback = function(ev) vim.bo[ev.buf].omnifunc = "v:lua.MiniCompletion.completefunc_lsp" end,
  })

  -- setup completion capabilities for every lsp
  vim.lsp.config("*", { capabilities = MiniCompletion.get_lsp_capabilities() })

  vim.api.nvim_create_autocmd("BufEnter", {
    desc = "Don't trigger autocomplete in prompts",
    group = _G.fgconf.augroup,
    callback = function(event)
      local buf = vim.bo[event.buf]

      if buf.buftype == "prompt" then
        vim.b.minicompletion_disable = true
        buf.omnifunc = ""
        buf.completefunc = ""
      end
    end,
  })
end)

later(function() require("mini.cursorword").setup() end)

later(function()
  local hipatterns = require("mini.hipatterns")
  local hi_words = MiniExtra.gen_highlighter.words
  hipatterns.setup({
    highlighters = {
      todo = hi_words({ "TODO" }, "MiniHipatternsTodo"),
      fixme = hi_words({ "FIXME" }, "MiniHipatternsFixme"),
      hex_color = hipatterns.gen_highlighter.hex_color(),
    },
  })
end)

-- later(function() require("mini.jump").setup() end)
-- later(function() require('mini.jump2d').setup() end)

later(function() require("mini.move").setup() end)
later(function() require("mini.pairs").setup() end)
-- }}}

-- {{{ treesitter
now_if_args(function()
  add({
    source = "nvim-treesitter/nvim-treesitter",
    checkout = "main",
    hooks = { post_checkout = function() vim.cmd("TSUpdate") end },
  })
  add({ source = "nvim-treesitter/nvim-treesitter-textobjects", checkout = "main" })

  -- language parsers to be installed and auto enabled
  local languages = {
    "bash",
    "bash",
    "c",
    "cmake",
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
    "lua",
    "luadoc",
    "make",
    "markdown",
    "markdown_inline",
    "python",
    "query",
    "regex",
    "ruby",
    "sql",
    "toml",
    "tsx",
    "typescript",
    "vim",
    "vimdoc",
    "yaml",
  }

  -- finds parsers not installed from the languages list and installs them
  local installed = require("nvim-treesitter.config").get_installed()
  local to_install = vim.tbl_filter(function(lang) return not vim.tbl_contains(installed, lang) end, languages)

  if #to_install > 0 then
    require("nvim-treesitter").install(to_install)
  end

  -- auto command enable tree-sitter after opening a file for a target language
  local filetypes = {}
  for _, lang in ipairs(languages) do
    for _, ft in ipairs(vim.treesitter.language.get_filetypes(lang)) do
      table.insert(filetypes, ft)
    end
  end

  local enable_ts = function(args)
    vim.treesitter.start(args.buf) --  highligting
    vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()" -- ts indent (experimental)
  end

  vim.api.nvim_create_autocmd("FileType", {
    group = _G.fgconf.augroup,
    pattern = filetypes,
    callback = enable_ts,
    desc = "Start treesitter",
  })
end)
-- }}}

-- {{{ lsp
now_if_args(function() add("neovim/nvim-lspconfig") end)

later(function()
  add("mason-org/mason.nvim")
  add("mason-org/mason-lspconfig.nvim")

  require("mason").setup()
  require("mason-lspconfig").setup({
    ensure_installed = {
      "pyrefly",
      "lua_ls",
      "ruff",
      "stylua",
      "yamlls",
    },
  })

  -- set diagnostic icons (replace stock H,W,E letters in the gutter)
  vim.diagnostic.config({
    update_in_insert = false, -- don't update diagnostics while typing
    severity_sort = true,
    float = { border = "rounded", source = "if_many" },
    underline = { severity = vim.diagnostic.severity.WARN },
    signs = {
      priority = 999,
      text = {
        [vim.diagnostic.severity.ERROR] = "󰅚 ",
        [vim.diagnostic.severity.WARN] = "󰀪 ",
        [vim.diagnostic.severity.INFO] = "󰋽 ",
        [vim.diagnostic.severity.HINT] = "󰌶 ",
      },
    },
    -- disable virtual text in favor of the autocmd
    -- virtual_text = {
    --   source = 'if_many',
    --   spacing = 2,
    --   format = function(diagnostic)
    --     local diagnostic_message = {
    --       [vim.diagnostic.severity.ERROR] = diagnostic.message,
    --       [vim.diagnostic.severity.WARN] = diagnostic.message,
    --       [vim.diagnostic.severity.INFO] = diagnostic.message,
    --       [vim.diagnostic.severity.HINT] = diagnostic.message,
    --     }
    --     return diagnostic_message[diagnostic.severity]
    --   end,
    -- },
  })

  -- auto command to open_float diagnostics when hovering over a line
  -- _G.fgmconf.autocmd("CursorHold", nil, function()
  --   local line_diagnostics = vim.diagnostic.get(0, { lnum = vim.api.nvim_win_get_cursor(0)[1] - 1 })
  --   if vim.fn.mode() == "n" and #line_diagnostics > 0 then
  --     vim.diagnostic.open_float({ focus = false, scope = "line" })
  --   end
  -- end, "Display diagnostic messages (if any) when hovering over a line")
end)
-- }}}

-- {{{ snacks
now(function()
  add("folke/snacks.nvim")

  require("snacks").setup({
    bigfile = { enabled = true },
    bufdelete = { enabled = true },
    indent = {
      animate = { enabled = false },
      enable = true,
    },
    notifier = { enable = true },
    quickfile = { enable = true },
    input = { enabled = true },
    picker = { enabled = true, ui_select = true },
  })
end)
-- }}}

-- {{{ neo-tree
now_if_args(function()
  add({
    source = "nvim-neo-tree/neo-tree.nvim",
    checkout = "v3.x",
    depends = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
    },
  })

  require("neo-tree").setup({
    sources = { "filesystem" },
    close_if_last_window = true,
    popup_border_style = "", -- use vim.o.winborder
    use_popups_for_input = false,
    event_handlers = {
      {
        event = "file_opened",
        handler = function(file_path) require("neo-tree.command").execute({ action = "close" }) end,
      },
    },
    window = {
      position = "float",
    },
    filesystem = {
      bind_to_cwd = false,
    },
  })
end)
-- }}}

-- {{{ conform
later(function()
  add("stevearc/conform.nvim")

  require("conform").setup({
    formatters_by_ft = {
      lua = { "stylua" },
      python = { "ruff_fix", "ruff_format" },
    },
    format_on_save = {
      timeout_ms = 500,
      lsp_format = "fallback",
    },
  })
end)
-- }}}

-- {{{ gitsigns
later(function()
  add({
    source = "lewis6991/gitsigns.nvim",
    depends = {
      "nvim-lua/plenary.nvim",
      "sindrets/diffview.nvim",
    },
  })

  vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile" }, {
    group = _G.fgconf.augroup,
    once = true,
    callback = function() require("gitsigns").setup() end,
  })
end)
-- }}}
