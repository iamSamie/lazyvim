local function diffget_current()
  vim.cmd("diffget")
end

local function diffput_current()
  vim.cmd("diffput")
end

local function diffget_selection()
  vim.cmd("'<,'>diffget")
end

local function diffput_selection()
  vim.cmd("'<,'>diffput")
end

return {
  {
    "sindrets/diffview.nvim",
    cmd = {
      "DiffviewClose",
      "DiffviewFileHistory",
      "DiffviewFocusFiles",
      "DiffviewLog",
      "DiffviewOpen",
      "DiffviewRefresh",
      "DiffviewToggleFiles",
    },
    opts = {
      enhanced_diff_hl = true,
      view = {
        default = {
          layout = "diff2_horizontal",
          winbar_info = true,
        },
        file_history = {
          layout = "diff2_horizontal",
          winbar_info = true,
        },
        merge_tool = {
          layout = "diff3_horizontal",
          disable_diagnostics = true,
          winbar_info = true,
        },
      },
      file_panel = {
        listing_style = "tree",
        tree_options = {
          flatten_dirs = true,
          folder_statuses = "only_folded",
        },
        win_config = {
          position = "left",
          width = 35,
        },
      },
      hooks = {
        diff_buf_read = function()
          vim.opt_local.wrap = false
          vim.opt_local.list = false
          vim.opt_local.cursorline = true
          vim.opt_local.signcolumn = "yes"
        end,
      },
      keymaps = {
        diff2 = {
          { "n", "gh", diffget_current, { desc = "Get hunk from the other side" } },
          { "n", "gH", diffput_current, { desc = "Put hunk to the other side" } },
          { "x", "gh", diffget_selection, { desc = "Get selection from the other side" } },
          { "x", "gH", diffput_selection, { desc = "Put selection to the other side" } },
        },
      },
    },
    keys = {
      { "<leader>gd", false },
      { "<leader>gD", false },
      { "<D-S-r>", "<cmd>DiffviewOpen<cr>", desc = "Git Diff View" },
      { "<D-R>", "<cmd>DiffviewOpen<cr>", desc = "Git Diff View" },
    },
  },
}
