local function find_project_root(path)
  return LazyVim and LazyVim.root.get({ path = path }) or vim.fn.getcwd()
end

local function detect_jest_command(project_root)
  if vim.uv.fs_stat(project_root .. "/pnpm-lock.yaml") then
    return "pnpm exec jest"
  end

  if vim.uv.fs_stat(project_root .. "/yarn.lock") then
    return "yarn jest"
  end

  return "npm exec jest"
end

return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-neotest/nvim-nio",
      "MunifTanjim/nui.nvim",
      "nvim-treesitter/nvim-treesitter",
      "nvim-neotest/neotest-jest",
      "fredrikaverpil/neotest-golang",
    },
    keys = {
      {
        "<leader>rn",
        function()
          require("neotest").run.run()
        end,
        desc = "Run Nearest Test",
      },
      {
        "<leader>rf",
        function()
          require("neotest").run.run(vim.fn.expand("%"))
        end,
        desc = "Run Test File",
      },
      {
        "<leader>ra",
        function()
          require("neotest").run.run(vim.uv.cwd())
        end,
        desc = "Run All Tests",
      },
      {
        "<leader>rl",
        function()
          require("neotest").run.run_last()
        end,
        desc = "Run Last Test",
      },
      {
        "<leader>ro",
        function()
          require("neotest").output.open({ enter = true, auto_close = true })
        end,
        desc = "Open Test Output",
      },
      {
        "<leader>rS",
        function()
          require("neotest").summary.toggle()
        end,
        desc = "Toggle Test Summary",
      },
    },
    opts = function()
      return {
        adapters = {
          require("neotest-jest")({
            jestCommand = function(path)
              return detect_jest_command(find_project_root(path))
            end,
            cwd = function(path)
              return find_project_root(path)
            end,
          }),
          require("neotest-golang")({}),
        },
      }
    end,
    config = function(_, opts)
      require("neotest").setup(opts)
    end,
  },
}
