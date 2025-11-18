-- run MiniDeps.now if nvim was started with args, else run MiniDeps.later
_G.fgconf.now_if_args = vim.fn.argc(-1) > 0 and MiniDeps.now or MiniDeps.later
