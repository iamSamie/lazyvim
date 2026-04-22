return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      local hover_options = {
        border = "rounded",
        max_width = 80,
        max_height = 20,
      }

      vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, hover_options)
      vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, hover_options)

      return opts
    end,
  },
}
