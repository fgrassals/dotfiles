-- keymaps - general and plugin specific
local function map(mode, keys, cmd, desc, opts)
  local options = { desc = desc or "", silent = true }

  if opts then
    options = vim.tbl_extend("force", options, opts)
  end

  vim.keymap.set(mode, keys, cmd, options)
end

--
-- buffers
local new_scratch_buffer = function() vim.api.nvim_win_set_buf(0, vim.api.nvim_create_buf(true, true)) end
map("n", "<leader>ba", "<cmd>b#<CR>", "Alternate")
map("n", "<leader>bd", function() Snacks.bufdelete() end, "Delete current buffer")
map("n", "<leader>bD", function() Snacks.bufdelete.all() end, "Delete all open buffer")
map("n", "<leader>bo", function() Snacks.bufdelete.other() end, "Delete other buffer")
map("n", "<leader>bs", function() Snacks.scratch() end, "Scratch")

-- pickers
map("n", "<leader><leader>", function() Snacks.picker.buffers() end, "Find Buffers")
map("n", "<leader>.", function() Snacks.picker.smart() end, "Smart Find Files")
map("n", "<leader>,", function() Snacks.picker.grep() end, "Grep")
map("n", "<leader>;", function() Snacks.picker.lsp_workspace_symbols() end, "Workspace Symbols")
map("n", "<leader>/", function() Snacks.picker.lines() end, "Grep Current Buffer")
map("n", "<leader>:", function() Snacks.picker.command_history() end, "Command History")
map("n", "<leader>n", function() Snacks.picker.notifications() end, "Notification History")
map("n", "<leader>un", function() Snacks.notifier.hide() end, "Dismiss all notifications")
map("n", "<leader>fc", function() Snacks.picker.files({ cwd = vim.fn.stdpath("config") }) end, "Find Config File")
map("n", "<leader>fh", function() Snacks.picker.help() end, "Find help")
map("n", "<leader>fr", function() Snacks.picker.recent() end, "Find recent")
map("n", "<leader>fs", function() Snacks.picker.lsp_symbols() end, "Find symbols (buffer)")
map({ "n", "x" }, "<leader>fw", function() Snacks.picker.grep_word() end, "Find word under cursor")

-- git
map("n", "<leader>gf", function() Snacks.picker.git_log_file() end, "Git log current file")
map("n", "<leader>gg", function() Snacks.lazygit() end, "Lazygit")
map("n", "<leader>gb", function() require("gitsigns").blame_line({ full = true }) end, "Blane line")
map("n", "<leader>gd", function() require("gitsigns").diffthis() end, "Diff this hunk")
map("n", "<leader>gD", function() require("gitsigns").diffthis("~") end, "Diff this buffer")
map("n", "<leader>gl", function() Snacks.picker.git_log_line() end, "Git log current line")
map("n", "<leader>gL", function() Snacks.picker.git_log() end, "Git log workspace")
map("n", "<leader>gp", function() require("gitsigns").preview_hunk() end, "Preview hunk")

-- lsp
map("n", "gd", vim.lsp.buf.definition, "Go to definition")
map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
map("n", "gr", function() Snacks.picker.lsp_references() end, "Go to references")
map("n", "gI", vim.lsp.buf.implementation, "Go to implementation")
map({ "n", "x" }, "<leader>ca", vim.lsp.buf.code_action, "Code actions")
map("n", "<leader>d", vim.diagnostic.open_float, "Line diagnostics")
map("n", "<leader>D", function() vim.diagnostic.open_float({ scope = "buffer" }) end, "Line diagnostics")
map("n", "<leader>rn", vim.lsp.buf.rename, "Rename")

-- mini deps
map("n", "<leader>uD", "<cmd>DepsUpdate<CR>", "Plugin updates")
map("n", "<leader>uS", "<cmd>DepsSnapSave<CR>", "Save deps snapshot")
map("n", "<leader>uL", "<cmd>DepsSnapLoad<CR>", "Load deps snapshot")
map("n", "<leader>uC", "<cmd>DepsClean<CR>", "Clean deps")

-- misc
map("n", "<Esc>", "<cmd>nohlsearch<CR>", "Clear search highlight")

-- sessions
map("n", "<leader>sd", function() MiniSessions.select("delete") end, "Delete")
map("n", "<leader>sn", function() MiniSessions.write(vim.fn.input("Session name: ")) end, "New")
map("n", "<leader>sr", function() MiniSessions.select("read") end, "Read")
map("n", "<leader>sw", function() MiniSessions.write() end, "Write current")

-- toggles
map("n", "<leader>e", "<cmd>Neotree toggle<CR>", "Toggle neo-tree at current file")
map("n", "<leader>th", function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled()) end, "Toggle inlay hints")
map("n", "<leader>tb", function() require("gitsigns").toggle_current_line_blame() end, "Toggle blame line")
map("n", "<leader>tw", function() require("gitsigns").toggle_word_diff() end, "Toggle word diff")

-- window splits
map("n", "<leader>sv", "<C-w>v", "Split window vertically")
map("n", "<leader>sh", "<C-w>s", "Split window horizontally")
map("n", "<leader>se", "<C-w>=", "Make split windows equal width & height")
map("n", "<leader>cs", "<lua> close<CR>", "Close current split window")

-- stay in visual mode after indenting
map("v", "<", "<gv")
map("v", ">", ">gv")

-- keep last yanked when pasting
map("v", "p", '"_dP')

-- delete single char without yanking
map("n", "x", '"_x')
