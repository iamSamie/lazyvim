return {
  {
    "lewis6991/gitsigns.nvim",
    enabled = true,
    lazy = false,
    opts = function(_, opts)
      local original_on_attach = opts.on_attach

      opts.auto_attach = false
      opts.current_line_blame = false
      opts.current_line_blame_opts = {
        delay = 200,
      }
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

        vim.keymap.set("n", "<leader>tb", function()
          gitsigns.toggle_current_line_blame()
        end, vim.tbl_extend("force", keymap_options, { desc = "Toggle Line Blame" }))

        vim.keymap.set("n", "<A-\\>", function()
          gitsigns.toggle_current_line_blame()
        end, vim.tbl_extend("force", keymap_options, { desc = "Toggle Line Blame" }))

        vim.keymap.set({ "n", "x" }, "<D-A-z>", function()
          gitsigns.reset_hunk()
        end, vim.tbl_extend("force", keymap_options, { desc = "Reset Git Hunk" }))
      end
    end,
    config = function(_, opts)
      local gitsigns = require("gitsigns")
      local attach_to_buffer = gitsigns.attach

      gitsigns.setup(opts)

      for _, autocommand in ipairs(vim.api.nvim_get_autocmds({ group = "gitsigns" })) do
        if autocommand.desc == "Gitsigns: attach" then
          vim.api.nvim_del_autocmd(autocommand.id)
        end
      end

      vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile", "BufWritePost" }, {
        group = vim.api.nvim_create_augroup("user_gitsigns_attach", { clear = true }),
        callback = function(event)
          local buffer_number = event.buf

          if not vim.api.nvim_buf_is_valid(buffer_number) or not vim.api.nvim_buf_is_loaded(buffer_number) then
            return
          end

          local buffer_name = vim.api.nvim_buf_get_name(buffer_number)

          if buffer_name == "" or vim.startswith(buffer_name, "widget-content-") or vim.startswith(buffer_name, "neo-tree ") then
            return
          end

          if vim.bo[buffer_number].buftype ~= "" then
            return
          end

          attach_to_buffer({ bufnr = buffer_number, trigger = event.event })
        end,
      })
    end,
  },
}
