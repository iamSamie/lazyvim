local function set_satellite_highlights()
  local set_highlight = vim.api.nvim_set_hl

  set_highlight(0, "SatelliteSearch", { fg = "#D8A45C", bg = "NONE" })
  set_highlight(0, "SatelliteSearchCurrent", { fg = "#D8A45C", bg = "NONE" })
  set_highlight(0, "SatelliteCursor", { fg = "#3D424A", bg = "NONE" })
  set_highlight(0, "SatelliteDiagnosticError", { fg = "#D96A7D", bg = "NONE" })
  set_highlight(0, "SatelliteDiagnosticWarn", { fg = "#D8A45C", bg = "NONE" })
  set_highlight(0, "SatelliteDiagnosticInfo", { fg = "#66B8E8", bg = "NONE" })
  set_highlight(0, "SatelliteDiagnosticHint", { fg = "#8AC76A", bg = "NONE" })
  set_highlight(0, "SatelliteGitSignsAdd", { fg = "#8AC76A", bg = "NONE" })
  set_highlight(0, "SatelliteGitSignsChange", { fg = "#66B8E8", bg = "NONE" })
  set_highlight(0, "SatelliteGitSignsDelete", { fg = "#D96A7D", bg = "NONE" })
end

return {
  {
    "lewis6991/satellite.nvim",
    event = "BufReadPost",
    opts = {
      current_only = true,
      winblend = 35,
      zindex = 40,
      width = 1,
      excluded_filetypes = {
        "neo-tree",
        "Trouble",
        "lazy",
        "mason",
        "snacks_picker_input",
        "snacks_picker_list",
      },
      handlers = {
        cursor = {
          enable = true,
          symbols = { "▏" },
        },
        search = {
          enable = true,
        },
        diagnostic = {
          enable = true,
          signs = { "▏", "▏", "▏" },
          min_severity = vim.diagnostic.severity.HINT,
        },
        gitsigns = {
          enable = false,
          signs = {
            add = "▏",
            change = "▏",
            delete = "▏",
          },
        },
        marks = {
          enable = false,
        },
        quickfix = {
          enable = false,
        },
      },
    },
    config = function(_, options)
      require("satellite").setup(options)

      set_satellite_highlights()
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("user_satellite_highlights", { clear = true }),
        callback = set_satellite_highlights,
      })
    end,
  },
}
