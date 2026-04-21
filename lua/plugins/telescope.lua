return {
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
      },
    },
    keys = {
      {
        "<leader><space>",
        function()
          require("telescope.builtin").live_grep({
            cwd = LazyVim.root(),
          })
        end,
        desc = "Grep (Root Dir)",
      },
      {
        "<leader>ff",
        function()
          require("telescope.builtin").find_files({
            cwd = LazyVim.root(),
            hidden = true,
          })
        end,
        desc = "Find Files (Root Dir)",
      },
      {
        "<leader>/",
        function()
          require("telescope.builtin").live_grep({
            cwd = LazyVim.root(),
          })
        end,
        desc = "Grep (Root Dir)",
      },
      {
        "<leader>f/",
        function()
          require("telescope.builtin").current_buffer_fuzzy_find()
        end,
        desc = "Search In Current Buffer",
      },
      {
        "<leader>fb",
        function()
          require("telescope.builtin").buffers()
        end,
        desc = "Buffers",
      },
      {
        "<leader>fr",
        function()
          require("telescope.builtin").oldfiles()
        end,
        desc = "Recent Files",
      },
      {
        "<leader>fh",
        function()
          require("telescope.builtin").help_tags()
        end,
        desc = "Help Pages",
      },
    },
    opts = function()
      local telescope_actions = require("telescope.actions")

      return {
        defaults = {
          vimgrep_arguments = {
            "rg",
            "--color=never",
            "--no-heading",
            "--with-filename",
            "--line-number",
            "--column",
            "--smart-case",
          },
          prompt_prefix = "  ",
          selection_caret = " ",
          path_display = { "truncate" },
          sorting_strategy = "ascending",
          layout_config = {
            prompt_position = "top",
          },
          mappings = {
            n = {
              ["<Esc>"] = telescope_actions.close,
            },
          },
        },
        pickers = {
          find_files = {
            hidden = true,
          },
        },
        extensions = {
          fzf = {
            fuzzy = true,
            override_file_sorter = true,
            override_generic_sorter = true,
            case_mode = "smart_case",
          },
        },
      }
    end,
    config = function(_, opts)
      local telescope = require("telescope")

      telescope.setup(opts)
      pcall(telescope.load_extension, "fzf")
    end,
  },
}
