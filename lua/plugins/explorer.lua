local function open_neotree()
  vim.schedule(function()
    local ok, command = pcall(require, "neo-tree.command")
    if not ok then
      return
    end

    local current_win = vim.api.nvim_get_current_win()
    command.execute({
      action = "show",
      source = "filesystem",
      position = "left",
      dir = LazyVim.root(),
      reveal = true,
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

local function open_git_diff(state)
  local node = state.tree:get_node()
  local is_file = node and node.type == "file"

  if not is_file then
    require("neo-tree.sources.git_status.commands").open(state)
    return
  end

  local ok, err = pcall(vim.cmd, "DiffviewOpen -- " .. vim.fn.fnameescape(node.path))
  if not ok then
    vim.notify("Diffview failed: " .. tostring(err), vim.log.levels.WARN)
  end
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

return {
  {
    "folke/snacks.nvim",
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
      opts.post_restore_cmds = opts.post_restore_cmds or {}
      opts.no_restore_cmds = opts.no_restore_cmds or {}

      table.insert(opts.post_restore_cmds, open_neotree)
      table.insert(opts.no_restore_cmds, wipe_regular_buffers)
      table.insert(opts.no_restore_cmds, open_neotree)
    end,
  },
}
