-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.g.lazyvim_explorer = "neo-tree"
vim.g.autoformat = true

vim.opt.number = true
vim.opt.relativenumber = false

-- Avoid horizontal scrolling in regular buffers.
vim.opt.wrap = true
vim.opt.linebreak = true

-- Keep more context visible before vertical scrolling starts.
vim.opt.scrolloff = 20

-- Always write a trailing newline at EOF.
vim.opt.fixendofline = true
