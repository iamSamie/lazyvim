local function set_diagnostic_highlights()
  vim.api.nvim_set_hl(0, "DiagnosticUnnecessary", {
    fg = "#7F848E",
    italic = true,
  })
end

local function open_padded_hover(_, result, _, config)
  if not (result and result.contents) then
    return
  end

  local hover_options = vim.tbl_deep_extend("force", {
    border = "rounded",
    max_width = 80,
    max_height = 20,
  }, config or {})

  local markdown_lines = vim.lsp.util.convert_input_to_markdown_lines(result.contents)
  markdown_lines = vim.lsp.util.trim_empty_lines(markdown_lines)

  local horizontal_padding = "   "
  local padded_lines = { "" }

  for _, markdown_line in ipairs(markdown_lines) do
    table.insert(padded_lines, horizontal_padding .. markdown_line .. horizontal_padding)
  end

  table.insert(padded_lines, "")

  return vim.lsp.util.open_floating_preview(padded_lines, "markdown", hover_options)
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

      vim.lsp.handlers["textDocument/hover"] = function(error_value, result, context, config)
        return open_padded_hover(error_value, result, context, vim.tbl_deep_extend("force", hover_options, config or {}))
      end
      vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, hover_options)

      return opts
    end,
  },
}
