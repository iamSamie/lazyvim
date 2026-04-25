return {
  {
    "lewis6991/gitsigns.nvim",
    opts = function(_, opts)
      local original_on_attach = opts.on_attach

      opts.on_attach = function(buffer)
        if original_on_attach then
          original_on_attach(buffer)
        end

        local gitsigns = package.loaded.gitsigns
        local keymap_options = { buffer = buffer, silent = true }

        vim.keymap.set("n", "<leader>ghb", function()
          gitsigns.blame()
        end, vim.tbl_extend("force", keymap_options, { desc = "Blame Buffer" }))

        vim.keymap.set("n", "<leader>ghB", function()
          gitsigns.blame_line({ full = true })
        end, vim.tbl_extend("force", keymap_options, { desc = "Blame Line" }))
      end
    end,
  },
}
