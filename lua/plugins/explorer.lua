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

return {
  { import = "lazyvim.plugins.extras.editor.neo-tree" },

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
    opts = {
      close_if_last_window = false,
      sources = { "filesystem", "buffers", "git_status" },
      filesystem = {
        follow_current_file = { enabled = true },
      },
      source_selector = {
        winbar = true,
        statusline = false,
        sources = {
          { source = "filesystem", display_name = " Files " },
          { source = "buffers", display_name = " Buffers " },
          { source = "git_status", display_name = " Git " },
        },
      },
      window = {
        position = "left",
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
    },
  },

  {
    "rmagatti/auto-session",
    opts = function(_, opts)
      opts.post_restore_cmds = opts.post_restore_cmds or {}
      opts.no_restore_cmds = opts.no_restore_cmds or {}

      table.insert(opts.post_restore_cmds, open_neotree)
      table.insert(opts.no_restore_cmds, open_neotree)
    end,
  },
}
