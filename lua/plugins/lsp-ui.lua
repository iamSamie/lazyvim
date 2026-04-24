local function set_diagnostic_highlights()
  vim.api.nvim_set_hl(0, "DiagnosticUnnecessary", {
    fg = "#7F848E",
    italic = true,
  })
end

return {
  {
    "neovim/nvim-lspconfig",
    init = function()
      local diagnostic_highlight_group = vim.api.nvim_create_augroup("user_diagnostic_highlights", { clear = true })

      set_diagnostic_highlights()

      vim.api.nvim_create_autocmd("ColorScheme", {
        group = diagnostic_highlight_group,
        callback = set_diagnostic_highlights,
      })
    end,
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
