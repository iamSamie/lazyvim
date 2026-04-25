local cached_memory_usage = ""
local last_memory_check = 0

local function get_process_snapshot()
  local result = vim.system({ "ps", "-axo", "pid=,ppid=,rss=,comm=" }, { text = true }):wait()

  if result.code ~= 0 then
    return nil
  end

  local processes_by_id = {}
  local child_processes_by_parent_id = {}

  for process_line in result.stdout:gmatch("[^\n]+") do
    local process_id, parent_process_id, memory_kb, command = process_line:match("^%s*(%d+)%s+(%d+)%s+(%d+)%s+(.+)%s*$")

    if process_id and parent_process_id and memory_kb and command then
      local numeric_process_id = tonumber(process_id)
      local numeric_parent_process_id = tonumber(parent_process_id)

      processes_by_id[numeric_process_id] = {
        id = numeric_process_id,
        memory_kb = tonumber(memory_kb) or 0,
        command = vim.fs.basename(vim.trim(command)),
      }
      child_processes_by_parent_id[numeric_parent_process_id] = child_processes_by_parent_id[numeric_parent_process_id] or {}
      table.insert(child_processes_by_parent_id[numeric_parent_process_id], numeric_process_id)
    end
  end

  return processes_by_id, child_processes_by_parent_id
end

local function get_process_tree(root_process_id)
  local processes_by_id, child_processes_by_parent_id = get_process_snapshot()

  if not processes_by_id then
    return nil
  end

  local process_tree = {}
  local process_ids_to_visit = { root_process_id }

  while #process_ids_to_visit > 0 do
    local process_id = table.remove(process_ids_to_visit)
    local process = processes_by_id[process_id]

    if process then
      table.insert(process_tree, process)
    end

    for _, child_process_id in ipairs(child_processes_by_parent_id[process_id] or {}) do
      table.insert(process_ids_to_visit, child_process_id)
    end
  end

  return process_tree
end

local function get_process_tree_memory_kb(root_process_id)
  local process_tree = get_process_tree(root_process_id)

  if not process_tree then
    return nil
  end

  local total_memory_kb = 0

  for _, process in ipairs(process_tree) do
    total_memory_kb = total_memory_kb + process.memory_kb
  end

  return total_memory_kb
end

local function format_memory(memory_kb)
  return math.floor(memory_kb / 1024) .. "M"
end

local function get_memory_usage()
  local now = vim.uv.now()

  if now - last_memory_check < 5000 then
    return cached_memory_usage
  end

  last_memory_check = now

  local process_id = vim.uv.os_getpid()
  local memory_kb = get_process_tree_memory_kb(process_id)

  if not memory_kb then
    return cached_memory_usage
  end

  cached_memory_usage = format_memory(memory_kb)

  return cached_memory_usage
end

local function remove_root_directory_component(components)
  for component_index, component in ipairs(components) do
    if type(component) == "function" then
      local component_info = debug.getinfo(component, "S")

      if component_info and component_info.source:find("lazyvim/util/lualine.lua", 1, true) then
        table.remove(components, component_index)
        return
      end
    end
  end
end

local function open_memory_summary()
  local process_tree = get_process_tree(vim.uv.os_getpid())

  if not process_tree then
    vim.notify("Failed to collect LazyVim memory usage", vim.log.levels.WARN)
    return
  end

  table.sort(process_tree, function(left_process, right_process)
    return left_process.memory_kb > right_process.memory_kb
  end)

  local total_memory_kb = 0
  local lines = { "LazyVim memory summary", "" }

  for _, process in ipairs(process_tree) do
    total_memory_kb = total_memory_kb + process.memory_kb
  end

  table.insert(lines, "Total: " .. format_memory(total_memory_kb))
  table.insert(lines, "")
  table.insert(lines, "Top processes:")

  for _, process in ipairs(process_tree) do
    table.insert(lines, string.format("%6s  %s  %s", format_memory(process.memory_kb), process.id, process.command))
  end

  vim.cmd("botright new")
  local buffer_number = vim.api.nvim_get_current_buf()

  vim.bo[buffer_number].buftype = "nofile"
  vim.bo[buffer_number].bufhidden = "wipe"
  vim.bo[buffer_number].swapfile = false
  vim.bo[buffer_number].filetype = "lazy_memory"
  vim.api.nvim_buf_set_name(buffer_number, "LazyMemory")
  vim.api.nvim_buf_set_lines(buffer_number, 0, -1, false, lines)
  vim.bo[buffer_number].modifiable = false
end

return {
  {
    "nvim-lualine/lualine.nvim",
    init = function()
      vim.api.nvim_create_user_command("LazyMemory", open_memory_summary, {
        desc = "Show LazyVim memory usage summary",
      })
    end,
    opts = function(_, opts)
      remove_root_directory_component(opts.sections.lualine_c)

      opts.sections.lualine_y = {
        { "location", padding = { left = 1, right = 1 } },
        { get_memory_usage, icon = "󰍛", padding = { left = 1, right = 1 } },
      }
    end,
  },
}
