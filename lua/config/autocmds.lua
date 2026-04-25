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

local function get_buffer_working_directory(bufnr)
  local buffer_name = vim.api.nvim_buf_get_name(bufnr)

  if not vim.startswith(buffer_name, "term://") then
    return nil
  end

  local terminal_working_directory = buffer_name:match("^term://(.-)//%d+:")

  if not terminal_working_directory or terminal_working_directory == "" then
    return nil
  end

  return vim.fs.normalize(terminal_working_directory)
end

local function get_current_git_root(bufnr)
  local target_buffer_number = bufnr or 0
  local buffer_name_success, current_buffer_name = pcall(vim.api.nvim_buf_get_name, target_buffer_number)

  if not buffer_name_success then
    target_buffer_number = 0
    buffer_name_success, current_buffer_name = pcall(vim.api.nvim_buf_get_name, target_buffer_number)
  end

  if not buffer_name_success then
    return vim.fs.root(vim.uv.cwd(), ".git")
  end

  if current_buffer_name ~= "" then
    local buffer_git_root = vim.fs.root(current_buffer_name, ".git")

    if buffer_git_root then
      return buffer_git_root
    end
  end

  local buffer_working_directory = get_buffer_working_directory(target_buffer_number)

  if buffer_working_directory then
    local terminal_git_root = vim.fs.root(buffer_working_directory, ".git")

    if terminal_git_root then
      return terminal_git_root
    end
  end

  return vim.fs.root(vim.uv.cwd(), ".git")
end

local function get_git_dir(git_root)
  local git_dir = run_git_command(git_root, { "rev-parse", "--git-dir" })

  if not git_dir or git_dir == "" then
    return nil
  end

  if vim.startswith(git_dir, "/") then
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

local function maybe_open_merge_diffview(bufnr)
  local current_filetype = vim.bo.filetype

  if current_filetype:match("^Diffview") then
    return
  end

  local git_root = get_current_git_root(bufnr)

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

  local git_root = get_current_git_root(0)
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

vim.api.nvim_create_autocmd({ "VimEnter", "FocusGained", "TermClose" }, {
  group = merge_diffview_group,
  desc = "Open Diffview for merge and rebase conflicts",
  callback = function(args)
    maybe_open_merge_diffview(args.buf)
  end,
})

local dependency_check_group = vim.api.nvim_create_augroup("user_dependency_check", { clear = true })
local dependency_check_state_directory = vim.fs.joinpath(vim.fn.stdpath("state"), "dependency-check")
local last_dependency_check_by_root = {}

local dependency_managers = {
  {
    name = "JavaScript dependencies",
    files = {
      ["package.json"] = true,
      ["pnpm-lock.yaml"] = true,
      ["yarn.lock"] = true,
      ["bun.lockb"] = true,
      ["package-lock.json"] = true,
    },
    commands = {
      { file = "pnpm-lock.yaml", command = "pnpm install" },
      { file = "yarn.lock", command = "yarn install" },
      { file = "bun.lockb", command = "bun install" },
      { file = "package-lock.json", command = "npm install" },
    },
    fallback_command = "npm install",
  },
  {
    name = "Go dependencies",
    files = {
      ["go.mod"] = true,
      ["go.sum"] = true,
    },
    commands = {
      { file = "go.mod", command = "go mod download" },
    },
    fallback_command = "go mod download",
  },
}

local function get_dependency_workspaces(git_root)
  local git_files = run_git_command(git_root, { "ls-files", "--cached", "--others", "--exclude-standard" })
  local workspaces_by_manager = {}

  if not git_files or git_files == "" then
    return workspaces_by_manager
  end

  for _, dependency_manager in ipairs(dependency_managers) do
    workspaces_by_manager[dependency_manager.name] = {}
  end

  for _, git_file in ipairs(vim.split(git_files, "\n", { trimempty = true })) do
    local file_name = vim.fs.basename(git_file)
    local workspace_directory = vim.fs.dirname(git_file)

    if workspace_directory == "." then
      workspace_directory = ""
    end

    for _, dependency_manager in ipairs(dependency_managers) do
      if dependency_manager.files[file_name] then
        local workspaces = workspaces_by_manager[dependency_manager.name]
        local workspace = workspaces[workspace_directory]

        if not workspace then
          workspace = {
            directory = workspace_directory,
            files = {},
            manager = dependency_manager,
          }
          workspaces[workspace_directory] = workspace
        end

        table.insert(workspace.files, file_name)
      end
    end
  end

  return workspaces_by_manager
end

local function get_dependency_file_signature(git_root, workspace)
  local signature_parts = {}

  table.sort(workspace.files)

  for _, dependency_file in ipairs(workspace.files) do
    local dependency_file_path = vim.fs.joinpath(git_root, workspace.directory, dependency_file)
    local dependency_file_stat = vim.uv.fs_stat(dependency_file_path)

    if dependency_file_stat then
      table.insert(signature_parts, dependency_file)
      table.insert(signature_parts, tostring(dependency_file_stat.size))
      table.insert(signature_parts, tostring(dependency_file_stat.mtime.sec))
      table.insert(signature_parts, tostring(dependency_file_stat.mtime.nsec))
    end
  end

  if #signature_parts == 0 then
    return nil
  end

  return table.concat(signature_parts, "\n")
end

local function get_dependency_install_command(git_root, workspace)
  for _, command_definition in ipairs(workspace.manager.commands) do
    if vim.uv.fs_stat(vim.fs.joinpath(git_root, workspace.directory, command_definition.file)) then
      return command_definition.command
    end
  end

  return workspace.manager.fallback_command
end

local function get_dependency_state_file(git_root, workspace)
  local state_key = vim.fn.sha256(git_root .. ":" .. workspace.manager.name .. ":" .. workspace.directory)

  return vim.fs.joinpath(dependency_check_state_directory, state_key .. ".txt")
end

local function read_dependency_state(state_file)
  local read_success, state_lines = pcall(vim.fn.readfile, state_file)

  if not read_success or #state_lines == 0 then
    return nil
  end

  return table.concat(state_lines, "\n")
end

local function write_dependency_state(state_file, signature)
  vim.fn.mkdir(dependency_check_state_directory, "p")
  vim.fn.writefile(vim.split(signature, "\n", { plain = true }), state_file)
end

local function maybe_notify_dependency_changes(bufnr)
  local git_root = get_current_git_root(bufnr)

  if not git_root then
    return
  end

  local now = vim.uv.now()
  local last_dependency_check = last_dependency_check_by_root[git_root]

  if last_dependency_check and now - last_dependency_check < 1000 then
    return
  end

  last_dependency_check_by_root[git_root] = now

  local changed_dependencies = {}
  local workspaces_by_manager = get_dependency_workspaces(git_root)

  for _, workspaces in pairs(workspaces_by_manager) do
    for _, workspace in pairs(workspaces) do
      local current_signature = get_dependency_file_signature(git_root, workspace)

      if current_signature then
        local state_file = get_dependency_state_file(git_root, workspace)
        local previous_signature = read_dependency_state(state_file)

        if not previous_signature then
          write_dependency_state(state_file, current_signature)
        elseif previous_signature ~= current_signature then
          write_dependency_state(state_file, current_signature)

          local install_command = get_dependency_install_command(git_root, workspace)
          local workspace_label = workspace.directory ~= "" and workspace.directory or "."

          table.insert(changed_dependencies, "- " .. workspace_label .. ": " .. install_command)
        end
      end
    end
  end

  if #changed_dependencies > 0 then
    table.sort(changed_dependencies)
    vim.notify("Dependencies changed:\n" .. table.concat(changed_dependencies, "\n"), vim.log.levels.WARN)
  end
end

vim.api.nvim_create_autocmd({ "VimEnter", "FocusGained", "TermClose" }, {
  group = dependency_check_group,
  desc = "Notify when project dependencies change",
  callback = function(args)
    vim.schedule(function()
      maybe_notify_dependency_changes(args.buf)
    end)
  end,
})

vim.api.nvim_create_autocmd("BufWritePost", {
  group = dependency_check_group,
  desc = "Notify when dependency files are saved",
  pattern = { "package.json", "pnpm-lock.yaml", "yarn.lock", "bun.lockb", "package-lock.json", "go.mod", "go.sum" },
  callback = function(args)
    vim.schedule(function()
      maybe_notify_dependency_changes(args.buf)
    end)
  end,
})
