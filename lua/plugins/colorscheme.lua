local function apply_darcula_overrides()
  local set = vim.api.nvim_set_hl

  -- Core UI palette from JetBrains Darcula defaults.
  set(0, "Normal", { fg = "#A9B7C6", bg = "#2B2D30" })
  set(0, "NormalNC", { fg = "#A9B7C6", bg = "#2B2D30" })
  set(0, "SignColumn", { bg = "#313335" })
  set(0, "LineNr", { fg = "#606366", bg = "#313335" })
  set(0, "CursorLineNr", { fg = "#C0C0C0", bg = "#323232", bold = true })
  set(0, "CursorLine", { bg = "#323232" })
  set(0, "ColorColumn", { bg = "#2F2F2F" })
  set(0, "VertSplit", { fg = "#4B4E52", bg = "#2B2D30" })
  set(0, "WinSeparator", { fg = "#4B4E52", bg = "#2B2D30" })
  set(0, "StatusLine", { fg = "#BBBBBB", bg = "#3C3F41" })
  set(0, "StatusLineNC", { fg = "#787878", bg = "#3C3F41" })
  set(0, "Visual", { bg = "#214283" })
  set(0, "Search", { fg = "#A9B7C6", bg = "#4B3A1F" })
  set(0, "IncSearch", { fg = "#A9B7C6", bg = "#5A2E00" })
  set(0, "MatchParen", { fg = "#FFEF28", bg = "#3B514D", bold = true })

  -- Floating/popup windows.
  set(0, "NormalFloat", { fg = "#BBBBBB", bg = "#46484A" })
  set(0, "FloatBorder", { fg = "#616161", bg = "#3C3F41" })
  set(0, "Pmenu", { fg = "#BBBBBB", bg = "#46484A" })
  set(0, "PmenuSel", { fg = "#BBBBBB", bg = "#2F65A8" })
  set(0, "PmenuSbar", { bg = "#46484A" })
  set(0, "PmenuThumb", { bg = "#616263" })
  set(0, "NormalSB", { fg = "#A9B7C6", bg = "#3C3F41" })
  set(0, "FloatTitle", { fg = "#A9B7C6", bg = "#3C3F41", bold = true })

  -- Syntax accents similar to Darcula.
  set(0, "Comment", { fg = "#8A8A8A", italic = true })
  set(0, "Keyword", { fg = "#FF9A4D" })
  set(0, "String", { fg = "#8FB573" })
  set(0, "Number", { fg = "#7AA6DA" })
  set(0, "Function", { fg = "#FFD866" })
  set(0, "Type", { fg = "#A9B7C6" })
  set(0, "Constant", { fg = "#B388FF" })
  set(0, "Identifier", { fg = "#A9B7C6" })
  set(0, "Operator", { fg = "#A9B7C6" })
  set(0, "Delimiter", { fg = "#C07C41" })
  set(0, "PreProc", { fg = "#BBB529" })
  set(0, "SpecialComment", { fg = "#8A653B", italic = true })

  -- Diagnostics and git/diff.
  set(0, "DiagnosticError", { fg = "#BC3F3C" })
  set(0, "DiagnosticWarn", { fg = "#A9B7C6" })
  set(0, "DiagnosticInfo", { fg = "#756D56" })
  set(0, "DiagnosticHint", { fg = "#787878" })
  set(0, "DiagnosticVirtualTextError", { bg = "#532B2E" })
  set(0, "DiagnosticVirtualTextWarn", { bg = "#52503A" })
  set(0, "DiagnosticVirtualTextInfo", { bg = "#3A3A3A" })
  set(0, "DiagnosticVirtualTextHint", { fg = "#787878", bg = "#3B3B3B" })
  set(0, "DiagnosticSignError", { fg = "#9E2927", bg = "#313335" })
  set(0, "DiagnosticSignWarn", { fg = "#BE9117", bg = "#313335" })
  set(0, "DiagnosticSignInfo", { fg = "#756D56", bg = "#313335" })
  set(0, "DiagnosticSignHint", { fg = "#6C7176", bg = "#313335" })
  set(0, "DiffAdd", { bg = "#294436" })
  set(0, "DiffChange", { bg = "#303C47" })
  set(0, "DiffDelete", { bg = "#484A4A" })
  set(0, "DiffText", { bg = "#385570" })

  -- Treesitter and semantic token mapping for TS/JS closer to JetBrains Darcula.
  set(0, "@comment", { link = "Comment" })
  set(0, "@keyword", { fg = "#FF9A4D" })
  set(0, "@keyword.return", { fg = "#FF9A4D" })
  set(0, "@keyword.function", { fg = "#FF9A4D" })
  set(0, "@keyword.operator", { fg = "#FF9A4D" })
  set(0, "@string", { link = "String" })
  set(0, "@string.escape", { fg = "#FF9A4D" })
  set(0, "@number", { link = "Number" })
  set(0, "@boolean", { fg = "#FF9A4D" })
  set(0, "@type", { fg = "#A9B7C6" })
  set(0, "@type.builtin", { fg = "#A9B7C6" })
  set(0, "@function", { fg = "#FFD866" })
  set(0, "@function.method", { fg = "#FFD866" })
  set(0, "@function.builtin", { fg = "#A9B7C6" })
  set(0, "@variable", { fg = "#A9B7C6" })
  set(0, "@variable.builtin", { fg = "#FF9A4D" })
  set(0, "@parameter", { fg = "#A9B7C6" })
  set(0, "@property", { fg = "#B388FF" })
  set(0, "@field", { fg = "#B388FF" })
  set(0, "@constructor", { fg = "#FFD866" })
  set(0, "@operator", { fg = "#A9B7C6" })
  set(0, "@punctuation", { fg = "#A9B7C6" })
  set(0, "@punctuation.delimiter", { fg = "#A9B7C6" })
  set(0, "@punctuation.bracket", { fg = "#A9B7C6" })
  set(0, "@tag", { fg = "#5CBAA5" })
  set(0, "@tag.attribute", { fg = "#BABABA" })

  set(0, "@lsp.type.class", { fg = "#A9B7C6" })
  set(0, "@lsp.type.enum", { fg = "#A9B7C6" })
  set(0, "@lsp.type.interface", { fg = "#A9B7C6" })
  set(0, "@lsp.type.type", { fg = "#A9B7C6" })
  set(0, "@lsp.type.typeParameter", { fg = "#A9B7C6" })
  set(0, "@lsp.type.function", { fg = "#F6C87B" })
  set(0, "@lsp.type.method", { fg = "#F6C87B" })
  set(0, "@lsp.type.parameter", { fg = "#A9B7C6" })
  set(0, "@lsp.type.variable", { fg = "#A9B7C6" })
  set(0, "@lsp.type.property", { fg = "#9876AA" })
  set(0, "@lsp.type.enumMember", { fg = "#9876AA" })
  set(0, "@lsp.type.namespace", { fg = "#A9B7C6" })
  set(0, "@lsp.type.keyword", { fg = "#C07C41" })

  -- Neo-tree and Diffview alignment with Darcula surfaces.
  set(0, "NeoTreeNormal", { fg = "#A9B7C6", bg = "#3A3D40" })
  set(0, "NeoTreeNormalNC", { fg = "#A9B7C6", bg = "#3A3D40" })
  set(0, "NeoTreeEndOfBuffer", { fg = "#606366", bg = "#3A3D40" })
  set(0, "NeoTreeCursorLine", { bg = "#1E3A5F" })
  set(0, "NeoTreeWinSeparator", { fg = "#4B4E52", bg = "#3A3D40" })
  set(0, "NeoTreeTitleBar", { fg = "#A9B7C6", bg = "#3A3D40", bold = false })
  set(0, "NeoTreeTabActive", { fg = "#A9B7C6", bg = "#3A3D40", bold = true })
  set(0, "NeoTreeTabInactive", { fg = "#A9B7C6", bg = "#3A3D40" })
  set(0, "NeoTreeTabSeparatorActive", { fg = "#3A3D40", bg = "#3A3D40" })
  set(0, "NeoTreeTabSeparatorInactive", { fg = "#3A3D40", bg = "#3A3D40" })
  set(0, "NeoTreeDirectoryName", { fg = "#A9B7C6" })
  set(0, "NeoTreeDirectoryIcon", { fg = "#A9B7C6" })
  set(0, "NeoTreeFileName", { fg = "#A9B7C6" })
  set(0, "NeoTreeGitAdded", { fg = "#629755" })
  set(0, "NeoTreeGitModified", { fg = "#6897BB" })
  set(0, "NeoTreeGitDeleted", { fg = "#CC666E" })

  set(0, "DiffviewNormal", { fg = "#A9B7C6", bg = "#2B2D30" })
  set(0, "DiffviewCursorLine", { bg = "#323232" })
  set(0, "DiffviewWinSeparator", { fg = "#606060", bg = "#2B2B2B" })
  set(0, "DiffviewStatusLine", { fg = "#BBBBBB", bg = "#3C3F41" })
  set(0, "DiffviewStatusLineNC", { fg = "#787878", bg = "#3C3F41" })

  set(0, "LspInlayHint", { fg = "#9A9A9A", bg = "#2B2D30" })

  -- Bufferline close to WebStorm tabs.
  set(0, "BufferLineFill", { bg = "#3C3F41" })
  set(0, "BufferLineBackground", { fg = "#8F96A0", bg = "#3C3F41" })
  set(0, "BufferLineBufferSelected", { fg = "#A9B7C6", bg = "#2B2D30" })
  set(0, "BufferLineSeparator", { fg = "#3C3F41", bg = "#3C3F41" })
  set(0, "BufferLineSeparatorSelected", { fg = "#3C3F41", bg = "#2B2D30" })
  set(0, "BufferLineIndicatorSelected", { fg = "#4A88C7", bg = "#2B2D30" })
  set(0, "BufferLineModifiedSelected", { fg = "#6897BB", bg = "#2B2D30" })
end

return {
  {
    "doums/darcula",
    lazy = false,
    priority = 1000,
  },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "darcula",
    },
  },

  {
    "doums/darcula",
    config = function()
      apply_darcula_overrides()
      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "darcula",
        callback = apply_darcula_overrides,
      })
    end,
  },
}
