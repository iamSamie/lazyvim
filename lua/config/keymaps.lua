-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local function terminal_root_directory()
  return vim.fn.fnameescape(LazyVim.root())
end

local function next_terminal_count()
  local terminal_manager = require("toggleterm.terminal")
  local terminal_list = terminal_manager.get_all(true)

  for terminal_index, terminal in ipairs(terminal_list) do
    if terminal_index ~= terminal.id then
      return terminal_index
    end
  end

  return #terminal_list + 1
end

local function toggle_terminal(terminal_count)
  vim.cmd(terminal_count .. "ToggleTerm direction=horizontal dir=" .. terminal_root_directory())
end

local function create_terminal()
  toggle_terminal(next_terminal_count())
end

local function toggle_all_terminals()
  local terminal_manager = require("toggleterm.terminal")
  local terminal_list = terminal_manager.get_all(true)

  if #terminal_list == 0 then
    toggle_terminal(1)
    return
  end

  vim.cmd("ToggleTermToggleAll")
end

vim.keymap.set({ "n", "t" }, "<C-`>", function()
  toggle_all_terminals()
end, { desc = "Toggle Terminal Section" })

vim.keymap.set({ "n", "t" }, "<C-/>", function()
  toggle_all_terminals()
end, { desc = "Toggle Terminal Section" })

vim.keymap.set({ "n", "t" }, "<leader>tt", function()
  create_terminal()
end, { desc = "New Terminal" })

vim.keymap.set("n", "<leader>ts", function()
  vim.cmd("TermSelect")
end, { desc = "Select Terminal" })

vim.keymap.set({ "n", "t" }, "<leader>t1", function()
  toggle_terminal(1)
end, { desc = "Terminal 1" })

vim.keymap.set({ "n", "t" }, "<leader>t2", function()
  toggle_terminal(2)
end, { desc = "Terminal 2" })

vim.keymap.set({ "n", "t" }, "<leader>t3", function()
  toggle_terminal(3)
end, { desc = "Terminal 3" })

local function next_buffer(exclude)
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if bufnr ~= exclude and vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].buflisted then
      return bufnr
    end
  end

  return nil
end

vim.keymap.set("n", "<C-w>", function()
  local current = vim.api.nvim_get_current_buf()
  local has_changes = vim.bo[current].modified

  if has_changes then
    local ok, error_message = pcall(vim.cmd, "write")
    if not ok then
      vim.notify("Save failed: " .. tostring(error_message), vim.log.levels.WARN)
      return
    end
  end

  local target = next_buffer(current)

  if target then
    vim.api.nvim_win_set_buf(0, target)
    vim.api.nvim_buf_delete(current, { force = true })
    return
  end

  vim.cmd("enew")
  vim.api.nvim_buf_delete(current, { force = true })
end, { desc = "Close Buffer (Save if Modified)" })

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
vim.keymap.set("n", "<D-j>", "<cmd>move .+1<cr>==", { desc = "Move Line Down" })
vim.keymap.set("n", "<D-k>", "<cmd>move .-2<cr>==", { desc = "Move Line Up" })
vim.keymap.set("x", "<D-j>", ":move '>+1<cr>gv=gv", { desc = "Move Selection Down" })
vim.keymap.set("x", "<D-k>", ":move '<-2<cr>gv=gv", { desc = "Move Selection Up" })

vim.keymap.set({ "n", "x" }, "<M-CR>", vim.lsp.buf.code_action, { desc = "Code Action" })
vim.keymap.set("n", "gt", vim.lsp.buf.type_definition, { desc = "Go to Type Definition" })
vim.keymap.set("n", "<leader>sd", "<cmd>Telescope diagnostics<cr>", { desc = "Search Diagnostics" })
