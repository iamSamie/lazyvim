return {
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}

      local tool_names = {
        "css-lsp",
        "emmet-ls",
        "graphql-language-service-cli",
        "html-lsp",
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
      opts.servers.cssls = opts.servers.cssls or {}
      opts.servers.graphql = opts.servers.graphql or {}
      opts.servers.html = opts.servers.html or {}
      opts.servers.emmet_ls = vim.tbl_deep_extend("force", opts.servers.emmet_ls or {}, {
        filetypes = {
          "css",
          "eruby",
          "html",
          "javascriptreact",
          "less",
          "sass",
          "scss",
          "typescriptreact",
        },
      })
    end,
  },
}
