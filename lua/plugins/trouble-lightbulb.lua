return {
  {
    "folke/trouble.nvim",
    keys = {
      {
        "<leader>xd",
        "<cmd>Trouble diagnostics toggle<cr>",
        desc = "Toggle Diagnostics",
      },
    },
  },
  {
    "kosayoda/nvim-lightbulb",
    event = "LspAttach",
    opts = {
      autocmd = {
        enabled = true,
      },
    },
    config = function(_, opts)
      require("nvim-lightbulb").setup(opts)
    end,
  },
}
