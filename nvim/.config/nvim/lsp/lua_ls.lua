return {
  settings = {
    Lua = {
      runtime = { version = "LuaJIT", path = vim.split(package.path, ";") },
      workspace = {
        -- Don't analyze code from submodules
        ignoreSubmodules = true,
        library = { vim.env.VIMRUNTIME },
        checkThirdParty = false,
      },
    },
  },
}
