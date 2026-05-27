-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.g.lazyvim_explorer = "neo-tree"
vim.g.autoformat = true

local temporary_directory = vim.uv.os_tmpdir()
local swap_directory = vim.fs.joinpath(temporary_directory, "nvim-swap")
vim.fn.mkdir(swap_directory, "p")
vim.opt.directory = swap_directory .. "//"

vim.opt.number = true
vim.opt.relativenumber = false
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Avoid horizontal scrolling in regular buffers.
vim.opt.wrap = true
vim.opt.linebreak = true

-- Keep more context visible before vertical scrolling starts.
vim.opt.scrolloff = 20

vim.opt.fillchars:append({
  horiz = "─",
  horizdown = "┬",
  horizup = "┴",
  vert = "│",
  verthoriz = "┼",
  vertleft = "┤",
  vertright = "├",
})

-- Always write a trailing newline at EOF.
vim.opt.fixendofline = true
