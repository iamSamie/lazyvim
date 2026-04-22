return {
  {
    "smoka7/multicursors.nvim",
    event = "VeryLazy",
    dependencies = {
      "nvimtools/hydra.nvim",
    },
    opts = function()
      local multicursors_normal_mode = require("multicursors.normal_mode")

      return {
        normal_keys = {
          ["<D-C-j>"] = {
            method = multicursors_normal_mode.create_down,
            opts = { desc = "Add Cursor Down" },
          },
          ["<D-C-k>"] = {
            method = multicursors_normal_mode.create_up,
            opts = { desc = "Add Cursor Up" },
          },
          j = false,
          k = false,
        },
      }
    end,
    keys = {
      {
        "<D-C-j>",
        function()
          require("multicursors").new_under_cursor()
          require("multicursors.normal_mode").create_down()
        end,
        mode = "n",
        desc = "Add Cursor Down",
      },
      {
        "<D-C-k>",
        function()
          require("multicursors").new_under_cursor()
          require("multicursors.normal_mode").create_up()
        end,
        mode = "n",
        desc = "Add Cursor Up",
      },
    },
  },
}
