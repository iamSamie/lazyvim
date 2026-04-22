return {
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}

      local tool_names = {
        "eslint-lsp",
        "prettier",
      }

      for _, tool_name in ipairs(tool_names) do
        if not vim.tbl_contains(opts.ensure_installed, tool_name) then
          table.insert(opts.ensure_installed, tool_name)
        end
      end
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      opts.servers.eslint = vim.tbl_deep_extend("force", opts.servers.eslint or {}, {
        settings = {
          workingDirectories = { mode = "auto" },
        },
      })
    end,
  },
}
