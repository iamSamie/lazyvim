return {
  {
    "kevinhwang91/nvim-hlslens",
    event = "VeryLazy",
    config = function()
      require("hlslens").setup()

      local function search_with_lens(search_key)
        return function()
          vim.cmd("normal! " .. search_key)
          require("hlslens").start()
        end
      end

      vim.keymap.set("n", "n", search_with_lens("n"), { desc = "Next Search Result" })
      vim.keymap.set("n", "N", search_with_lens("N"), { desc = "Previous Search Result" })
      vim.keymap.set("n", "*", search_with_lens("*"), { desc = "Search Word Under Cursor" })
      vim.keymap.set("n", "#", search_with_lens("#"), { desc = "Search Word Under Cursor Backward" })
    end,
  },
}
