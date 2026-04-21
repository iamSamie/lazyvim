-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set({ "n", "t" }, "<C-`>", function()
  Snacks.terminal(nil, { cwd = LazyVim.root() })
end, { desc = "Terminal (Root Dir)" })

local function next_buffer(exclude)
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if bufnr ~= exclude and vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].buflisted then
      return bufnr
    end
  end

  return nil
end

vim.keymap.set("n", "<C-w>", function()
  local ok, err = pcall(vim.cmd, "write")
  if not ok then
    vim.notify("Save failed: " .. tostring(err), vim.log.levels.WARN)
    return
  end

  local current = vim.api.nvim_get_current_buf()
  local target = next_buffer(current)

  if target then
    vim.api.nvim_win_set_buf(0, target)
    vim.api.nvim_buf_delete(current, { force = true })
    return
  end

  vim.cmd("enew")
  vim.api.nvim_buf_delete(current, { force = true })
end, { desc = "Save and Close Buffer" })

vim.keymap.set("n", "<D-C-c>p", function()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    vim.notify("No file path to copy", vim.log.levels.WARN)
    return
  end

  local rel = vim.fs.relpath(file, LazyVim.root()) or vim.fn.fnamemodify(file, ":.")

  vim.fn.setreg("+", rel)
  vim.fn.setreg("*", rel)
  vim.notify("Copied path: " .. rel)
end, { desc = "Copy Relative File Path" })

vim.keymap.set("n", "<D-/>", "gcc", { desc = "Comment Line", remap = true })
vim.keymap.set("x", "<D-/>", "gc", { desc = "Comment Selection", remap = true })
