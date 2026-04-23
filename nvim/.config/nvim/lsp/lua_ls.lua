return {
  settings = {
    Lua = {
      runtime = { version = 'LuaJIT' },
      workspace = {
        ignoreSubmodules = true,
        library = { vim.env.VIMRUNTIME },
        -- workspace = { checkThirdParty = false },
        telemetry = { enable = false },
      }
    }
  }
}
