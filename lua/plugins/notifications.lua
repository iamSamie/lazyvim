return {
  {
    "folke/noice.nvim",
    opts = {
      views = {
        mini = {
          timeout = 6000,
        },
      },
    },
    config = function(_, opts)
      require("noice").setup(opts)

      local function set_noice_highlights()
        vim.api.nvim_set_hl(0, "NoiceMini", { bg = "#2a2f3a" })
        vim.api.nvim_set_hl(0, "NoiceMiniTitle", { bg = "#2a2f3a" })
      end

      set_noice_highlights()

      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = set_noice_highlights,
      })
    end,
  },
  {
    "snacks.nvim",
    opts = {
      notifier = {
        enabled = false,
      },
    },
  },
}
