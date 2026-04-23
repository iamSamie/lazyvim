local function set_scrollbar_highlights()
  local set_highlight = vim.api.nvim_set_hl

  set_highlight(0, "ScrollbarHandle", { fg = "#3D424A", bg = "NONE" })
  set_highlight(0, "ScrollbarSearch", { fg = "#D8A45C", bg = "NONE" })
  set_highlight(0, "ScrollbarError", { fg = "#D96A7D", bg = "NONE" })
  set_highlight(0, "ScrollbarWarn", { fg = "#D8A45C", bg = "NONE" })
  set_highlight(0, "ScrollbarInfo", { fg = "#66B8E8", bg = "NONE" })
  set_highlight(0, "ScrollbarHint", { fg = "#8AC76A", bg = "NONE" })
  set_highlight(0, "ScrollbarGitAdd", { fg = "#8AC76A", bg = "NONE" })
  set_highlight(0, "ScrollbarGitChange", { fg = "#66B8E8", bg = "NONE" })
  set_highlight(0, "ScrollbarGitDelete", { fg = "#D96A7D", bg = "NONE" })

  set_highlight(0, "ScrollbarSearchHandle", { fg = "#D8A45C", bg = "NONE" })
  set_highlight(0, "ScrollbarErrorHandle", { fg = "#D96A7D", bg = "NONE" })
  set_highlight(0, "ScrollbarWarnHandle", { fg = "#D8A45C", bg = "NONE" })
  set_highlight(0, "ScrollbarInfoHandle", { fg = "#66B8E8", bg = "NONE" })
  set_highlight(0, "ScrollbarHintHandle", { fg = "#8AC76A", bg = "NONE" })
  set_highlight(0, "ScrollbarGitAddHandle", { fg = "#8AC76A", bg = "NONE" })
  set_highlight(0, "ScrollbarGitChangeHandle", { fg = "#66B8E8", bg = "NONE" })
  set_highlight(0, "ScrollbarGitDeleteHandle", { fg = "#D96A7D", bg = "NONE" })
end

return {
  {
    "petertriho/nvim-scrollbar",
    event = "BufReadPost",
    dependencies = {
      "lewis6991/gitsigns.nvim",
    },
    opts = {
      hide_if_all_visible = false,
      show_in_active_only = true,
      set_highlights = false,
      max_lines = false,
      handle = {
        text = "▏",
        blend = 35,
        highlight = "ScrollbarHandle",
      },
      autocmd = {
        render = {
          "BufWinEnter",
          "TabEnter",
          "TermEnter",
          "WinEnter",
          "CmdwinLeave",
          "TextChanged",
          "VimResized",
          "WinScrolled",
          "DiagnosticChanged",
        },
        clear = {
          "BufWinLeave",
          "TabLeave",
          "TermLeave",
          "WinLeave",
        },
      },
      excluded_filetypes = {
        "neo-tree",
        "Trouble",
        "lazy",
        "mason",
        "snacks_picker_input",
        "snacks_picker_list",
      },
      handlers = {
        cursor = false,
        diagnostic = true,
        gitsigns = true,
        search = true,
      },
      marks = {
        Search = { text = "▏", highlight = "ScrollbarSearch" },
        Error = { text = "▏", highlight = "ScrollbarError" },
        Warn = { text = "▏", highlight = "ScrollbarWarn" },
        Info = { text = "▏", highlight = "ScrollbarInfo" },
        Hint = { text = "▏", highlight = "ScrollbarHint" },
        GitAdd = { text = "▏", highlight = "ScrollbarGitAdd" },
        GitChange = { text = "▏", highlight = "ScrollbarGitChange" },
        GitDelete = { text = "▏", highlight = "ScrollbarGitDelete" },
      },
    },
    config = function(_, options)
      require("scrollbar").setup(options)
      require("scrollbar.handlers.search").setup()
      require("scrollbar.handlers.gitsigns").setup()

      set_scrollbar_highlights()
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("user_scrollbar_highlights", { clear = true }),
        callback = set_scrollbar_highlights,
      })
    end,
  },
}
