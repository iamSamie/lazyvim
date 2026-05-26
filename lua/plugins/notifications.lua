return {
  {
    "folke/noice.nvim",
    opts = {
      notify = {
        enabled = true,
        view = "notify",
        replace = false,
        merge = false,
      },
      views = {
        mini = {
          timeout = 7000,
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
        enabled = true,
        timeout = 7000,
        width = { min = 80, max = 80 },
        margin = { top = 0, right = 1, bottom = 2 },
        padding = true,
        gap = 1,
        top_down = false,
        style = "compact",
      },
    },
  },
}
