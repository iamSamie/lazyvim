local group = vim.api.nvim_create_augroup("user_todo_highlight", { clear = true })

local pattern = [[\v<(TODO|todo|FIXME|fixme|HACK|hack|NOTE|note|WARN|warn):]]

vim.api.nvim_set_hl(0, "Todo", { fg = "#FFB86C", bold = true })

local function add_todo_match()
  if vim.w.user_todo_match_id then
    return
  end

  vim.w.user_todo_match_id = vim.fn.matchadd("Todo", pattern, 10)
end

vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter", "FileType" }, {
  group = group,
  callback = add_todo_match,
})

return {}
