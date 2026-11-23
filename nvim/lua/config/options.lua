-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

opts = { ensure_installed = { "java" } }

-- Terminal and Ghostty tab title. The startup banner is set in lua/plugins/dashboard.lua.
vim.opt.title = true
vim.opt.titlestring = "Neovim"
