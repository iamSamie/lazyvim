return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    event = "VeryLazy",
    cmd = {
      "TermExec",
      "TermNew",
      "TermSelect",
      "ToggleTerm",
      "ToggleTermToggleAll",
    },
    opts = {
      close_on_exit = false,
      direction = "horizontal",
      float_opts = {
        border = "curved",
        height = function()
          return math.floor(vim.o.lines * 0.85)
        end,
        width = function()
          return math.floor(vim.o.columns * 0.9)
        end,
      },
      insert_mappings = true,
      persist_mode = true,
      persist_size = true,
      shade_terminals = false,
      size = 15,
      start_in_insert = true,
      terminal_mappings = true,
    },
  },
}
