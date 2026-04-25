return {
  {
    "folke/flash.nvim",
    keys = {
      { "s", mode = "x", false },
    },
  },
  {
    "kylechui/nvim-surround",
    version = "*",
    event = "VeryLazy",
    init = function()
      vim.g.nvim_surround_no_visual_mappings = true
    end,
    opts = {},
    config = function(_, opts)
      require("nvim-surround").setup(opts)

      local function set_surround_keymaps()
        vim.keymap.set("x", "s", "<Plug>(nvim-surround-visual)", {
          remap = true,
          desc = "Add a surrounding pair around a visual selection",
        })

        vim.keymap.set("x", '"', 's"', { remap = true, desc = "Surround with double quotes" })
        vim.keymap.set("x", "'", "s'", { remap = true, desc = "Surround with single quotes" })
        vim.keymap.set("x", "`", "s`", { remap = true, desc = "Surround with backticks" })
        vim.keymap.set("x", "(", "s(", { remap = true, desc = "Surround with parentheses" })
        vim.keymap.set("x", "[", "s[", { remap = true, desc = "Surround with brackets" })
        vim.keymap.set("x", "{", "s{", { remap = true, desc = "Surround with braces" })
      end

      set_surround_keymaps()
      vim.schedule(set_surround_keymaps)
    end,
  },
}
