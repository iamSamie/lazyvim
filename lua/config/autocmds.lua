-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

local autosave_group = vim.api.nvim_create_augroup("user_autosave", { clear = true })

vim.api.nvim_create_autocmd({ "BufLeave", "FocusLost", "InsertLeave", "VimLeavePre" }, {
  group = autosave_group,
  desc = "Autosave regular modified files",
  callback = function(args)
    local bufnr = args.buf

    if not vim.api.nvim_buf_is_valid(bufnr) then
      return
    end

    if vim.bo[bufnr].buftype ~= "" or not vim.bo[bufnr].modifiable or vim.bo[bufnr].readonly then
      return
    end

    if vim.api.nvim_buf_get_name(bufnr) == "" or not vim.bo[bufnr].modified then
      return
    end

    vim.api.nvim_buf_call(bufnr, function()
      vim.cmd("silent! update")
    end)
  end,
})

local function restore_filetype_and_treesitter(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  local bo = vim.bo[bufnr]
  if bo.buftype ~= "" then
    return
  end

  if bo.filetype == "" then
    local filename = vim.api.nvim_buf_get_name(bufnr)
    local filetype = filename ~= "" and vim.filetype.match({ filename = filename, buf = bufnr }) or nil

    if filetype and filetype ~= "" then
      vim.api.nvim_buf_call(bufnr, function()
        vim.cmd("setfiletype " .. filetype)
      end)
    end
  end

  local highlighters = vim.treesitter.highlighter and vim.treesitter.highlighter.active
  if bo.filetype ~= "" and not (highlighters and highlighters[bufnr]) then
    pcall(vim.treesitter.start, bufnr)
  end
end

local treesitter_group = vim.api.nvim_create_augroup("user_treesitter_start", { clear = true })
vim.api.nvim_create_autocmd({ "BufReadPost", "BufWinEnter", "FileType" }, {
  group = treesitter_group,
  desc = "Restore filetype and treesitter highlighting for restored buffers",
  callback = function(args)
    restore_filetype_and_treesitter(args.buf)
  end,
})

vim.schedule(function()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      restore_filetype_and_treesitter(bufnr)
    end
  end
end)
