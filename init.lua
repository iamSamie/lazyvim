if vim.loader and vim.loader.enable then
  vim.loader.enable(false)
end

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
