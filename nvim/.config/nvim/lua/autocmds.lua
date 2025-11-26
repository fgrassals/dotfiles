-- global autocmds

_G.fgconf.augroup = vim.api.nvim_create_augroup("fg-config-group", { clear = true })

-- don't remember where I got this from.. probably from reddit
vim.api.nvim_create_autocmd("LspProgress", {
  group = _G.fgconf.augroup,
  callback = function(ev)
    local spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
    vim.notify(vim.lsp.status(), vim.log.levels.INFO, {
      id = "lsp_progress",
      title = "LSP Progress",
      opts = function(notif) notif.icon = ev.data.params.value.kind == "end" and " " or spinner[math.floor(vim.uv.hrtime() / (1e6 * 80)) % #spinner + 1] end,
    })
  end,
})
