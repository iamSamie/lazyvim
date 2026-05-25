local function open_neotree()
  vim.schedule(function()
    local ok, command = pcall(require, "neo-tree.command")
    if not ok then
      return
    end

    local current_win = vim.api.nvim_get_current_win()
    local current_buffer = vim.api.nvim_get_current_buf()
    local current_buffer_name = vim.api.nvim_buf_get_name(current_buffer)
    local should_reveal_current_file = current_buffer_name == "" or vim.uv.fs_stat(current_buffer_name) ~= nil

    command.execute({
      action = "show",
      source = "filesystem",
      position = "left",
      dir = LazyVim.root(),
      reveal = should_reveal_current_file,
    })

    if vim.api.nvim_win_is_valid(current_win) then
      pcall(vim.api.nvim_set_current_win, current_win)
    end
  end)
end

local folder_icon_definitions = {
  [".docker"] = { icon = "", color = "#33B5E5", name = "Docker" },
  [".git"] = { icon = "", color = "#F14E32", name = "Git" },
  [".gitlab-ci"] = { icon = "", color = "#FC6D26", name = "GitLab" },
  [".husky"] = { icon = "󰜫", color = "#C8CCD4", name = "Husky" },
  [".idea"] = { icon = "", color = "#B86AD9", name = "Idea" },
  [".settings"] = { icon = "", color = "#66B8E8", name = "Settings" },
  actions = { icon = "󰒓", color = "#B86AD9", name = "Actions" },
  app = { icon = "󰏗", color = "#D96A7D", name = "App" },
  constants = { icon = "󰏿", color = "#66B8E8", name = "Constants" },
  dist = { icon = "󰉥", color = "#D96A7D", name = "Dist" },
  docs = { icon = "󰈙", color = "#66B8E8", name = "Docs" },
  entities = { icon = "󰆧", color = "#56B6C2", name = "Entities" },
  features = { icon = "󰙅", color = "#8AC76A", name = "Features" },
  helpers = { icon = "󰘦", color = "#D8D85C", name = "Helpers" },
  i18n = { icon = "󰗊", color = "#66B8E8", name = "I18n" },
  model = { icon = "󰆼", color = "#56B6C2", name = "Model" },
  node_modules = { icon = "", color = "#8AC76A", name = "NodeModules" },
  pages = { icon = "󰈔", color = "#66B8E8", name = "Pages" },
  projects = { icon = "󰲋", color = "#56B6C2", name = "Projects" },
  rules = { icon = "󰁨", color = "#D96A7D", name = "Rules" },
  shared = { icon = "󰒗", color = "#D8A45C", name = "Shared" },
  src = { icon = "󰉋", color = "#5FA8FF", name = "Src" },
  widgets = { icon = "󰕮", color = "#B86AD9", name = "Widgets" },
}

local function set_folder_icon_highlights()
  for _, folder_icon_definition in pairs(folder_icon_definitions) do
    vim.api.nvim_set_hl(0, "NeoTreeMaterialFolder" .. folder_icon_definition.name, {
      fg = folder_icon_definition.color,
      bg = "NONE",
    })
  end
end

local function neo_tree_icon_provider(icon, node)
  if node.type == "directory" then
    local folder_icon_definition = folder_icon_definitions[node.name]

    if folder_icon_definition then
      icon.text = folder_icon_definition.icon
      icon.highlight = "NeoTreeMaterialFolder" .. folder_icon_definition.name
    end

    return icon
  end

  if node.type == "file" or node.type == "terminal" then
    local has_devicons, devicons = pcall(require, "nvim-web-devicons")
    local name = node.type == "terminal" and "terminal" or node.name

    if has_devicons then
      local devicon, highlight = devicons.get_icon(name)
      icon.text = devicon or icon.text
      icon.highlight = highlight or icon.highlight
    end
  end

  return icon
end

local function wipe_regular_buffers()
  for _, buffer_number in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buffer_number) and vim.bo[buffer_number].buflisted then
      local buffer_options = vim.bo[buffer_number]

      if buffer_options.buftype == "" then
        pcall(vim.api.nvim_buf_delete, buffer_number, { force = true })
      end
    end
  end
end

local function wipe_missing_file_buffers()
  for _, buffer_number in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buffer_number) and vim.bo[buffer_number].buflisted then
      local buffer_options = vim.bo[buffer_number]
      local buffer_name = vim.api.nvim_buf_get_name(buffer_number)

      if buffer_options.buftype == "" and buffer_name ~= "" and vim.uv.fs_stat(buffer_name) == nil then
        pcall(vim.api.nvim_buf_delete, buffer_number, { force = true })
      end
    end
  end
end

local function has_startup_arguments()
  return vim.fn.argc() > 0
end

local is_session_restoring = false

local function has_listed_regular_file_buffer()
  for _, buffer_number in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buffer_number) and vim.bo[buffer_number].buflisted then
      local buffer_options = vim.bo[buffer_number]
      local buffer_name = vim.api.nvim_buf_get_name(buffer_number)

      if buffer_options.buftype == "" and buffer_name ~= "" and vim.uv.fs_stat(buffer_name) ~= nil then
        return true
      end
    end
  end

  return false
end

local function get_dashboard_target_window()
  local current_window = vim.api.nvim_get_current_win()
  local current_buffer = vim.api.nvim_win_get_buf(current_window)

  if vim.bo[current_buffer].filetype ~= "neo-tree" then
    return current_window
  end

  for _, window_number in ipairs(vim.api.nvim_list_wins()) do
    local window_buffer = vim.api.nvim_win_get_buf(window_number)
    local is_floating_window = vim.api.nvim_win_get_config(window_number).relative ~= ""

    if not is_floating_window and vim.bo[window_buffer].filetype ~= "neo-tree" then
      return window_number
    end
  end

  return nil
end

local function open_dashboard_if_no_files(delay)
  local dashboard_delay = type(delay) == "number" and delay or 50

  vim.defer_fn(function()
    if is_session_restoring then
      return
    end

    if has_listed_regular_file_buffer() then
      return
    end

    local dashboard_ok, dashboard = pcall(require, "snacks.dashboard")

    if not dashboard_ok then
      return
    end

    local target_window = get_dashboard_target_window()

    if not target_window then
      return
    end

    local current_buffer = vim.api.nvim_win_get_buf(target_window)

    if vim.bo[current_buffer].filetype == "snacks_dashboard" then
      return
    end

    if vim.api.nvim_buf_get_name(current_buffer) ~= "" or vim.bo[current_buffer].modified then
      return
    end

    local dashboard_buffer = vim.api.nvim_create_buf(false, true)
    pcall(dashboard.open, { buf = dashboard_buffer, win = target_window })
  end, dashboard_delay)
end

local function finish_session_restore()
  vim.defer_fn(function()
    is_session_restoring = false
    wipe_missing_file_buffers()
    open_dashboard_if_no_files(100)
  end, 300)
end

local function open_git_diff(state)
  local node = state.tree:get_node()
  local is_file = node and node.type == "file"

  if not is_file then
    require("neo-tree.sources.git_status.commands").open(state)
    return
  end

  local function open_git_diff_for_path(file_path)
    local target_window = get_dashboard_target_window()

    if not target_window then
      vim.notify("Нет окна для открытия diff", vim.log.levels.WARN)
      return
    end

    local repo_root = LazyVim.root()
    local relative_file_path = file_path:gsub(vim.pesc(repo_root .. "/"), "", 1)
    local head_file_lines = vim.fn.systemlist({
      "git",
      "-C",
      repo_root,
      "show",
      "HEAD:" .. relative_file_path,
    })

    if vim.v.shell_error ~= 0 then
      vim.notify("Не удалось получить версию файла из HEAD", vim.log.levels.WARN)
      return
    end

    for _, window_number in ipairs(vim.api.nvim_list_wins()) do
      local window_buffer = vim.api.nvim_win_get_buf(window_number)
      local buffer_name = vim.api.nvim_buf_get_name(window_buffer)

      if vim.startswith(buffer_name, "git://HEAD/") then
        pcall(vim.api.nvim_win_close, window_number, true)
      end
    end

    vim.api.nvim_set_current_win(target_window)
    vim.cmd("diffoff!")
    vim.cmd("edit " .. vim.fn.fnameescape(file_path))
    vim.cmd("diffthis")

    local working_tree_buffer = vim.api.nvim_get_current_buf()
    local working_tree_filetype = vim.bo[working_tree_buffer].filetype

    vim.cmd("leftabove vnew")

    local head_buffer = vim.api.nvim_get_current_buf()

    vim.bo[head_buffer].buftype = "nofile"
    vim.bo[head_buffer].bufhidden = "wipe"
    vim.bo[head_buffer].buflisted = false
    vim.bo[head_buffer].swapfile = false
    vim.bo[head_buffer].modifiable = true
    vim.bo[head_buffer].readonly = false
    vim.bo[head_buffer].filetype = working_tree_filetype

    vim.api.nvim_buf_set_lines(head_buffer, 0, -1, false, head_file_lines)
    vim.api.nvim_buf_set_name(head_buffer, "git://HEAD/" .. relative_file_path)
    vim.b[head_buffer].is_git_diff_head = true

    vim.bo[head_buffer].modifiable = false
    vim.bo[head_buffer].readonly = true

    vim.cmd("diffthis")
    vim.api.nvim_set_current_win(target_window)
    vim.cmd("wincmd l")
    vim.cmd("wincmd =")
  end

  open_git_diff_for_path(node.path)
end

local function get_git_diff_target_file_path()
  for _, window_number in ipairs(vim.api.nvim_list_wins()) do
    local window_buffer = vim.api.nvim_win_get_buf(window_number)
    local buffer_name = vim.api.nvim_buf_get_name(window_buffer)
    local is_floating_window = vim.api.nvim_win_get_config(window_number).relative ~= ""

    if not is_floating_window and vim.wo[window_number].diff and not vim.startswith(buffer_name, "git://HEAD/") then
      return buffer_name
    end
  end

  local current_buffer_name = vim.api.nvim_buf_get_name(0)

  if current_buffer_name ~= "" and not vim.startswith(current_buffer_name, "git://HEAD/") then
    return current_buffer_name
  end

  return nil
end

local function get_changed_git_file_paths()
  local repo_root = LazyVim.root()
  local changed_file_lines = vim.fn.systemlist({
    "git",
    "-C",
    repo_root,
    "status",
    "--short",
    "--no-renames",
    "--untracked-files=all",
  })

  if vim.v.shell_error ~= 0 then
    vim.notify("Не удалось получить список изменённых файлов", vim.log.levels.WARN)
    return {}
  end

  local changed_file_paths = {}

  for _, changed_file_line in ipairs(changed_file_lines) do
    local relative_file_path = vim.trim(changed_file_line:sub(4))

    if relative_file_path ~= "" then
      table.insert(changed_file_paths, vim.fs.joinpath(repo_root, relative_file_path))
    end
  end

  return changed_file_paths
end

local function navigate_git_diff_file(step)
  local current_file_path = get_git_diff_target_file_path()

  if not current_file_path then
    vim.notify("Сейчас не открыт git diff файла", vim.log.levels.INFO)
    return
  end

  local changed_file_paths = get_changed_git_file_paths()

  if #changed_file_paths == 0 then
    vim.notify("Нет изменённых файлов", vim.log.levels.INFO)
    return
  end

  local current_file_index = nil

  for file_index, changed_file_path in ipairs(changed_file_paths) do
    if vim.fs.normalize(changed_file_path) == vim.fs.normalize(current_file_path) then
      current_file_index = file_index
      break
    end
  end

  if not current_file_index then
    vim.notify("Текущий файл не найден в git status", vim.log.levels.INFO)
    return
  end

  local target_file_index = current_file_index + step

  if target_file_index < 1 then
    target_file_index = #changed_file_paths
  end

  if target_file_index > #changed_file_paths then
    target_file_index = 1
  end

  local target_file_path = changed_file_paths[target_file_index]
  local target_file_state = {
    tree = {
      get_node = function()
        return {
          path = target_file_path,
          type = "file",
        }
      end,
    },
  }

  open_git_diff(target_file_state)
end

local function accept_git_diff_change()
  if not vim.wo.diff then
    vim.notify("Команда работает только в diff режиме", vim.log.levels.INFO)
    return
  end

  vim.cmd("diffget")
end

local function reset_git_hunk()
  require("gitsigns").reset_hunk()
end

local function grep_in_directory(state)
  local node = state.tree:get_node()

  if not node then
    vim.notify("No node selected", vim.log.levels.WARN)
    return
  end

  if node.type ~= "directory" then
    vim.notify("Select a directory in Neo-tree", vim.log.levels.WARN)
    return
  end

  require("telescope.builtin").live_grep({
    cwd = node.path,
  })
end

local function show_neotree()
  require("neo-tree.command").execute({ action = "show", source = "filesystem", position = "left", dir = LazyVim.root() })
end

local function show_neotree_git()
  require("neo-tree.command").execute({ action = "show", source = "git_status", position = "left", dir = LazyVim.root() })
end

local function close_git_diff()
  local closed_head_window = false

  for _, window_number in ipairs(vim.api.nvim_list_wins()) do
    local buffer_number = vim.api.nvim_win_get_buf(window_number)
    local buffer_name = vim.api.nvim_buf_get_name(buffer_number)

    if vim.startswith(buffer_name, "git://HEAD/") then
      pcall(vim.api.nvim_win_close, window_number, true)
      closed_head_window = true
    end
  end

  if closed_head_window then
    for _, window_number in ipairs(vim.api.nvim_list_wins()) do
      local buffer_number = vim.api.nvim_win_get_buf(window_number)
      local is_floating_window = vim.api.nvim_win_get_config(window_number).relative ~= ""

      if not is_floating_window and vim.bo[buffer_number].filetype ~= "neo-tree" and vim.wo[window_number].diff then
        vim.api.nvim_win_call(window_number, function()
          vim.cmd("diffoff")
        end)
      end
    end

    vim.cmd("wincmd =")
    return
  end

  if vim.fn.exists(":DiffviewClose") == 2 then
    vim.cmd("DiffviewClose")
  end
end

local function focus_file_instead_of_quitting_neotree()
  local current_buffer = vim.api.nvim_get_current_buf()

  if vim.bo[current_buffer].filetype ~= "neo-tree" then
    vim.cmd("quit")
    return
  end

  for _, window_number in ipairs(vim.api.nvim_list_wins()) do
    local window_buffer = vim.api.nvim_win_get_buf(window_number)
    local is_floating_window = vim.api.nvim_win_get_config(window_number).relative ~= ""

    if not is_floating_window and vim.bo[window_buffer].filetype ~= "neo-tree" then
      vim.api.nvim_set_current_win(window_number)
      return
    end
  end

  vim.notify("Нет окна с файлом для переключения", vim.log.levels.INFO)
end

return {
  {
    "folke/snacks.nvim",
    init = function()
      vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
        group = vim.api.nvim_create_augroup("user_open_dashboard_when_no_files", { clear = true }),
        desc = "Open dashboard when the last file buffer is closed",
        callback = function(args)
          if is_session_restoring then
            return
          end

          local filetype_success, deleted_filetype = pcall(function()
            return vim.bo[args.buf].filetype
          end)

          if filetype_success and (deleted_filetype == "snacks_dashboard" or deleted_filetype == "neo-tree") then
            return
          end

          open_dashboard_if_no_files()
        end,
      })
    end,
    keys = {
      { "<leader>fe", false },
      { "<leader>fE", false },
      { "<leader>e", false },
      { "<leader>E", false },
    },
  },

  {
    "nvim-neo-tree/neo-tree.nvim",
    init = function()
      set_folder_icon_highlights()

      vim.api.nvim_create_user_command("SmartQuit", focus_file_instead_of_quitting_neotree, {})
      vim.cmd([[cnoreabbrev <expr> q getcmdtype() == ':' && getcmdline() ==# 'q' ? 'SmartQuit' : 'q']])

      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("user_neotree_material_folder_icons", { clear = true }),
        callback = set_folder_icon_highlights,
      })
    end,
    keys = {
      { "<leader>e", false },
      {
        "<leader>E",
        show_neotree,
        desc = "Explorer NeoTree",
      },
      {
        "<D-S-e>",
        show_neotree,
        desc = "Explorer NeoTree",
      },
      {
        "<D-E>",
        show_neotree,
        desc = "Explorer NeoTree",
      },
      {
        "<leader>R",
        show_neotree_git,
        desc = "Explorer NeoTree Git",
      },
      {
        "<leader>gd",
        close_git_diff,
        desc = "Close Git Diff",
      },
      {
        "<leader>ga",
        accept_git_diff_change,
        desc = "Accept Git Diff Change",
      },
      {
        "<leader>gr",
        reset_git_hunk,
        desc = "Reset Git Hunk",
      },
    },
    opts = {
      close_if_last_window = true,
      default_component_configs = {
        icon = {
          provider = neo_tree_icon_provider,
        },
      },
      sources = { "filesystem", "git_status" },
      filesystem = {
        follow_current_file = { enabled = true },
        filtered_items = {
          visible = true,
          hide_dotfiles = false,
          hide_gitignored = false,
          hide_ignored = false,
          hide_hidden = false,
        },
      },
      source_selector = {
        winbar = true,
        statusline = false,
        sources = {
          { source = "filesystem", display_name = " Files " },
          { source = "git_status", display_name = " Git " },
        },
      },
      window = {
        position = "left",
        width = 43,
        mappings = {
          ["<leader>fd"] = "grep_in_directory",
        },
      },
      git_status = {
        commands = {
          open_git_diff = open_git_diff,
        },
        window = {
          mappings = {
            ["<cr>"] = "open_git_diff",
            ["l"] = "open_git_diff",
          },
        },
      },
      commands = {
        grep_in_directory = grep_in_directory,
      },
    },
  },

  {
    "rmagatti/auto-session",
    opts = function(_, opts)
      opts.pre_restore_cmds = opts.pre_restore_cmds or {}
      opts.post_restore_cmds = opts.post_restore_cmds or {}
      opts.no_restore_cmds = opts.no_restore_cmds or {}

      table.insert(opts.pre_restore_cmds, function()
        is_session_restoring = true
      end)
      table.insert(opts.post_restore_cmds, finish_session_restore)
      table.insert(opts.post_restore_cmds, open_neotree)
      table.insert(opts.no_restore_cmds, function()
        if has_startup_arguments() then
          return
        end

        wipe_regular_buffers()
      end)
      table.insert(opts.no_restore_cmds, function()
        if has_startup_arguments() then
          return
        end

        open_dashboard_if_no_files()
      end)
      table.insert(opts.no_restore_cmds, function()
        if has_startup_arguments() then
          return
        end

        open_neotree()
      end)
    end,
  },
}
