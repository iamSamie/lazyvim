return {
  {
    "saghen/blink.cmp",
    opts = function(_, opts)
      local temporary_directory = vim.uv.os_tmpdir()
      local blink_directory = vim.fs.joinpath(temporary_directory, "blink-cmp")
      local frecency_path = vim.fs.joinpath(blink_directory, "frecency.dat")
      local completion_menu_padding = 3
      local documentation_padding = 3

      vim.fn.mkdir(blink_directory, "p")

      opts.fuzzy = opts.fuzzy or {}
      opts.fuzzy.frecency = opts.fuzzy.frecency or {}
      opts.fuzzy.frecency.path = frecency_path

      opts.completion = opts.completion or {}
      opts.completion.menu = opts.completion.menu or {}
      opts.completion.menu.border = "rounded"
      opts.completion.menu.draw = opts.completion.menu.draw or {}
      opts.completion.menu.draw.padding = { completion_menu_padding, completion_menu_padding }
      opts.completion.documentation = opts.completion.documentation or {}
      opts.completion.documentation.draw = function(documentation_options)
        documentation_options.default_implementation()

        local documentation_buffer = documentation_options.window:get_buf()

        if not vim.api.nvim_buf_is_valid(documentation_buffer) then
          return
        end

        if not vim.bo[documentation_buffer].modifiable then
          return
        end

        local documentation_lines = vim.api.nvim_buf_get_lines(documentation_buffer, 0, -1, false)
        local horizontal_padding = string.rep(" ", documentation_padding)
        local padded_documentation_lines = {}

        for _, documentation_line in ipairs(documentation_lines) do
          table.insert(padded_documentation_lines, horizontal_padding .. documentation_line .. horizontal_padding)
        end

        vim.api.nvim_buf_set_lines(documentation_buffer, 0, -1, false, padded_documentation_lines)
      end
      opts.completion.documentation.window = opts.completion.documentation.window or {}
      opts.completion.documentation.window.border = "rounded"

      opts.keymap = opts.keymap or {}
      opts.keymap["<D-Space>"] = {
        function(cmp)
          return cmp.show({ providers = { "lsp" } })
        end,
        "show_documentation",
        "hide_documentation",
      }
    end,
  },
}
