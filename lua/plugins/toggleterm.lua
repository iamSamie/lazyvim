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
