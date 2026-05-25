return {
  {
    "folke/persistence.nvim",
    enabled = false,
  },
  {
    "rmagatti/auto-session",
    lazy = false,
    opts = {
      auto_save = true,
      auto_create = true,
      auto_restore = true,
      args_allow_files_auto_save = true,
      git_use_branch_name = true,
      git_auto_restore_on_branch_change = true,
      bypass_save_filetypes = { "alpha" },
      suppressed_dirs = { "~/", "~/Downloads", "/" },
    },
    keys = {
      { "<leader>qs", "<cmd>AutoSession restore<cr>", desc = "Restore Session" },
      { "<leader>qS", "<cmd>AutoSession search<cr>", desc = "Select Session" },
      { "<leader>qw", "<cmd>AutoSession save<cr>", desc = "Save Session" },
      { "<leader>qd", "<cmd>AutoSession disable<cr>", desc = "Don't Save Current Session" },
      { "<leader>qD", "<cmd>AutoSession delete<cr>", desc = "Delete Session" },
      { "<leader>qt", "<cmd>AutoSession toggle<cr>", desc = "Toggle Session Autosave" },
    },
  },
}
