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
map("n", "<leader>bd", "<cmd>lua snacks.bufdelete()<CR>", "Delete current buffer")
map("n", "<leader>bD", "<cmd>lua snacks.bufdelete.all()<CR>", "Delete all open buffer")
map("n", "<leader>bo", "<cmd>lua snacks.bufdelete.other()<CR>", "Delete other buffer")
map("n", "<leader>bs", "<cmd>lua Snacks.scratch()<CR>", "Scratch")

-- pickers
map("n", "<leader><leader>", "<cmd>lua Snacks.picker.buffers()<CR>", "Find Buffers")
map("n", "<leader>.", "<cmd>lua Snacks.picker.smart()<CR>", "Smart Find Files")
map("n", "<leader>,", "<cmd>lua Snacks.picker.grep()<CR>", "Grep")
map("n", "<leader>;", "<cmd>lua Snacks.picker.lsp_workspace_symbols()<CR>", "Workspace Symbols")
map("n", "<leader>/", "<cmd>lua Snacks.picker.lines()<CR>", "Grep Current Buffer")
map("n", "<leader>:", "<cmd>lua Snacks.picker.command_history()<CR>", "Command History")
map("n", "<leader>n", "<cmd>lua Snacks.picker.notifications()<CR>", "Notification History")
map("n", "<leader>un", "<cmd>lua Snacks.notifier.hide()", "Dismiss all notifications")
map("n", "<leader>fc", "<cmd>lua Snacks.picker.files({ cwd = vim.fn.stdpath('config') })<CR>", "Find Config File")
map("n", "<leader>fh", "<cmd>lua Snacks.picker.help()<CR>", "Find help")
map("n", "<leader>fr", "<cmd>lua Snacks.picker.recent()<CR>", "Find recent")
map("n", "<leader>fs", "<cmd>lua Snacks.picker.lsp_symbols()<CR>", "Find symbols (buffer)")
map({ "n", "x" }, "<leader>fw", "<cmd>lua Snacks.grep_word()<CR>", "Find word under cursor")

-- git
map("n", "<leader>gf", "<cmd>lua Snacks.picker.git_log_file()<CR>", "Git log current file")
map("n", "<leader>gg", "<cmd>lua Snacks.lazygit()<CR>", "Lazygit")
map("n", "<leader>gb", "<cmd>lua gitsigns.blame_line({ full = true })<CR>", "Blane line")
map("n", "<leader>gd", "<cmd>lua gitsigns.diffthis()<CR>", "Diff this hunk")
map("n", "<leader>gD", "<cmd>lua gitsigns.diffthis('~')<CR>", "Diff this buffer")
map("n", "<leader>gl", "<cmd>lua Snacks.picker.git_log_line()<CR>", "Git log current line")
map("n", "<leader>gL", "<cmd>lua Snacks.picker.git_log()<CR>", "Git log workspace")
map("n", "<leader>gp", "<cmd>lua gitsigns.preview_hunk()<CR>", "Preview hunk")

-- lsp
map("n", "gd", vim.lsp.buf.definition, "Go to definition")
map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
map("n", "gr", "<cmd>lua Snacks.picker.lsp_references()<CR>", "Go to references")
map("n", "gI", vim.lsp.buf.implementation, "Go to implementation")
map({ "n", "x" }, "<leader>ca", vim.lsp.buf.code_action, "Code actions")

-- misc
map("n", "<Esc>", "<cmd>nohlsearch<CR>", "Clear search highlight")

-- sessions
local session_new = 'MiniSessions.write(vim.fn.input("Session name: "))'

map("n", "<leader>sd", '<cmd>lua MiniSessions.select("delete")<CR>', "Delete")
map("n", "<leader>sn", "<cmd>lua " .. session_new .. "<CR>", "New")
map("n", "<leader>sr", '<cmd>lua MiniSessions.select("read")<CR>', "Read")
map("n", "<leader>sw", "<cmd>lua MiniSessions.write()<CR>", "Write current")

-- toggles
map("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", "Toggle nvim-tree")
map("n", "<leader>th", function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled()) end, "Toggle inlay hints")
map("n", "<leader>tb", "<cmd>lua gitsigns.toggle_current_line_blame()<CR>", "Toggle blame line")
map("n", "<leader>tw", "<cmd>gitsigns.toggle_word_diff()<CR>", "Toggle word diff")

-- window splits
map("n", "<leader>sv", "<C-w>v", "Split window vertically")
map("n", "<leader>sh", "<C-w>s", "Split window horizontally")
map("n", "<leader>se", "<C-w>=", "Make split windows equal width & height")
map("n", "<leader>cs", "<lua> close<CR>", "Close current split window")
