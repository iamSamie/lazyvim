return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    event = "VeryLazy",
    cmd = {
      "TermExec",
      "TermNew",
      "TermSelect",
      "ToggleTerm",
      "ToggleTermToggleAll",
    },
    opts = {
      close_on_exit = false,
      direction = "float",
      float_opts = {
        border = "rounded",
        height = function()
          return math.floor(vim.o.lines * 0.85)
        end,
        width = function()
          return math.floor(vim.o.columns * 0.9)
        end,
      },
      insert_mappings = true,
      persist_mode = false,
      persist_size = true,
      shade_terminals = false,
      size = 15,
      start_in_insert = true,
      terminal_mappings = true,
      hide_numbers = false,
      on_open = function(terminal)
        if not terminal.window then
          return
        end

        vim.wo[terminal.window].winbar = "%!v:lua.render_toggleterm_winbar()"

        if terminal.direction == "float" then
          vim.wo[terminal.window].winhighlight = "FloatBorder:ToggleTermBorder"
        end
      end,
    },
    config = function(_, options)
      local function open_terminal_by_identifier(terminal_identifier)
        local terminal_manager = require("toggleterm.terminal")
        local current_buffer_number = vim.api.nvim_get_current_buf()
        local target_terminal = terminal_manager.get(terminal_identifier)

        if target_terminal and target_terminal.bufnr == current_buffer_number then
          return
        end

        for current_terminal_identifier = 1, 3 do
          local current_terminal = terminal_manager.get(current_terminal_identifier)

          if current_terminal and current_terminal.bufnr == current_buffer_number and current_terminal:is_open() then
            current_terminal:close()
            break
          end
        end

        vim.cmd(terminal_identifier .. "ToggleTerm")
      end

      _G.handle_toggleterm_tab_click = function(minimum_width)
        open_terminal_by_identifier(minimum_width)
      end

      _G.render_toggleterm_winbar = function()
        local terminal_manager = require("toggleterm.terminal")
        local current_buffer_number = vim.api.nvim_get_current_buf()
        local terminal_labels = {}

        for terminal_identifier = 1, 3 do
          local terminal = terminal_manager.get(terminal_identifier)
          local is_current_terminal = terminal and terminal.bufnr == current_buffer_number
          local label_highlight_group = is_current_terminal and "%#ToggleTermTabActive#" or "%#ToggleTermTabInactive#"
          local bracket_highlight_group = is_current_terminal and "%#ToggleTermTabBracketActive#" or "%#ToggleTermTabBracketInactive#"
          local index_highlight_group = is_current_terminal and "%#ToggleTermTabIndexActive#" or "%#ToggleTermTabIndexInactive#"

          table.insert(
            terminal_labels,
            string.format(
              "%%%d@v:lua.handle_toggleterm_tab_click@%s[%s%d%s]%%T ",
              terminal_identifier,
              bracket_highlight_group,
              index_highlight_group,
              terminal_identifier,
              bracket_highlight_group
            )
          )
          table.insert(terminal_labels, string.format("%s", label_highlight_group))
        end

        return "%#ToggleTermTabFill# " .. table.concat(terminal_labels)
      end

      local function set_toggleterm_window_options(buffer_number)
        local window_identifier = vim.fn.bufwinid(buffer_number)

        if window_identifier == -1 then
          return
        end

        vim.wo[window_identifier].winbar = "%!v:lua.render_toggleterm_winbar()"
      end

      local function set_toggleterm_highlights()
        vim.api.nvim_set_hl(0, "ToggleTermBorder", { fg = "#7dcfff" })
        vim.api.nvim_set_hl(0, "ToggleTermTabActive", { fg = "#7dcfff", bold = true })
        vim.api.nvim_set_hl(0, "ToggleTermTabInactive", { fg = "#a9b1d6" })
        vim.api.nvim_set_hl(0, "ToggleTermTabIndexActive", { fg = "#e0af68", bold = true })
        vim.api.nvim_set_hl(0, "ToggleTermTabIndexInactive", { fg = "#565f89" })
        vim.api.nvim_set_hl(0, "ToggleTermTabBracketActive", { fg = "#7dcfff", bold = true })
        vim.api.nvim_set_hl(0, "ToggleTermTabBracketInactive", { fg = "#565f89" })
        vim.api.nvim_set_hl(0, "ToggleTermTabSeparator", { fg = "#3b4261" })
        vim.api.nvim_set_hl(0, "ToggleTermTabFill", { fg = "#7aa2f7" })
      end

      set_toggleterm_highlights()

      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("user_toggleterm_highlights", { clear = true }),
        callback = set_toggleterm_highlights,
      })

      vim.api.nvim_create_autocmd({ "BufWinEnter", "TermOpen" }, {
        group = vim.api.nvim_create_augroup("user_toggleterm_winbar", { clear = true }),
        callback = function(args)
          if vim.bo[args.buf].buftype ~= "terminal" then
            return
          end

          set_toggleterm_window_options(args.buf)
        end,
      })

      require("toggleterm").setup(options)
    end,
  },
}
