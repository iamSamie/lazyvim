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

local merge_diffview_group = vim.api.nvim_create_augroup("user_merge_diffview", { clear = true })
local last_merge_conflict_signature = nil

local function open_merge_diffview(show_notification)
  if show_notification then
    vim.notify("Merge conflicts detected: opening Diffview", vim.log.levels.INFO)
  end

  if vim.fn.exists(":DiffviewOpen") == 0 then
    require("lazy").load({ plugins = { "diffview.nvim" } })
  end

  if vim.fn.exists(":DiffviewOpen") == 0 then
    return
  end

  vim.cmd("DiffviewOpen")
end

local function run_git_command(git_root, arguments)
  local git_result = vim.system(vim.list_extend({ "git" }, arguments), {
    cwd = git_root,
    text = true,
  }):wait()

  if git_result.code ~= 0 then
    return nil
  end

  return vim.trim(git_result.stdout)
end

local function get_current_git_root()
  local current_buffer_name = vim.api.nvim_buf_get_name(0)

  if current_buffer_name ~= "" then
    local buffer_git_root = vim.fs.root(current_buffer_name, ".git")

    if buffer_git_root then
      return buffer_git_root
    end
  end

  return vim.fs.root(vim.uv.cwd(), ".git")
end

local function get_git_dir(git_root)
  local git_dir = run_git_command(git_root, { "rev-parse", "--git-dir" })

  if not git_dir or git_dir == "" then
    return nil
  end

  if vim.fs.isabsolute(git_dir) then
    return vim.fs.normalize(git_dir)
  end

  return vim.fs.normalize(vim.fs.joinpath(git_root, git_dir))
end

local function is_merge_or_rebase_in_progress(git_dir)
  if not git_dir then
    return false
  end

  return vim.uv.fs_stat(vim.fs.joinpath(git_dir, "MERGE_HEAD")) ~= nil
    or vim.uv.fs_stat(vim.fs.joinpath(git_dir, "rebase-merge")) ~= nil
    or vim.uv.fs_stat(vim.fs.joinpath(git_dir, "rebase-apply")) ~= nil
end

local function get_conflicted_files(git_root)
  local conflicted_files = run_git_command(git_root, { "diff", "--name-only", "--diff-filter=U" })

  if not conflicted_files or conflicted_files == "" then
    return {}
  end

  return vim.split(conflicted_files, "\n", { trimempty = true })
end

local function maybe_open_merge_diffview()
  local current_filetype = vim.bo.filetype

  if current_filetype:match("^Diffview") then
    return
  end

  local git_root = get_current_git_root()

  if not git_root then
    last_merge_conflict_signature = nil
    return
  end

  local git_dir = get_git_dir(git_root)

  if not is_merge_or_rebase_in_progress(git_dir) then
    last_merge_conflict_signature = nil
    return
  end

  local conflicted_files = get_conflicted_files(git_root)

  if #conflicted_files == 0 then
    last_merge_conflict_signature = nil
    return
  end

  local current_signature = table.concat({ git_dir, unpack(conflicted_files) }, "\n")

  if current_signature == last_merge_conflict_signature then
    return
  end

  last_merge_conflict_signature = current_signature

  vim.schedule(function()
    open_merge_diffview(true)
  end)
end

vim.api.nvim_create_user_command("DiffviewMergeConflicts", function()
  last_merge_conflict_signature = nil

  local git_root = get_current_git_root()
  local git_dir = git_root and get_git_dir(git_root) or nil
  local conflicted_files = git_root and get_conflicted_files(git_root) or {}

  if not is_merge_or_rebase_in_progress(git_dir) or #conflicted_files == 0 then
    vim.notify("No active merge or rebase conflicts found", vim.log.levels.INFO)
    return
  end

  local current_signature = table.concat({ git_dir, unpack(conflicted_files) }, "\n")
  last_merge_conflict_signature = current_signature
  open_merge_diffview(false)
end, {
  desc = "Open Diffview for current merge or rebase conflicts",
})

vim.api.nvim_create_autocmd({ "VimEnter", "FocusGained" }, {
  group = merge_diffview_group,
  desc = "Open Diffview for merge and rebase conflicts",
  callback = function()
    maybe_open_merge_diffview()
  end,
})
