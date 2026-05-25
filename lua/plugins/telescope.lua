local function is_git_repository(directory_path)
  return vim.uv.fs_stat(vim.fs.joinpath(directory_path, ".git")) ~= nil
end

local function get_git_branch(directory_path)
  local git_output = vim.fn.systemlist({
    "git",
    "-C",
    directory_path,
    "rev-parse",
    "--abbrev-ref",
    "HEAD",
  })[1]

  if vim.v.shell_error ~= 0 or not git_output or git_output == "" then
    return "unknown"
  end

  if git_output == "HEAD" then
    return "detached"
  end

  return git_output
end

local function has_git_changes(directory_path)
  local git_output = vim.fn.systemlist({
    "git",
    "-C",
    directory_path,
    "status",
    "--porcelain",
  })

  return vim.v.shell_error == 0 and #git_output > 0
end

local function has_git_upstream(directory_path)
  vim.fn.system({
    "git",
    "-C",
    directory_path,
    "rev-parse",
    "--abbrev-ref",
    "--symbolic-full-name",
    "@{upstream}",
  })

  return vim.v.shell_error == 0
end

local function get_git_sync_status(directory_path)
  if not has_git_upstream(directory_path) then
    return {
      ahead_count = 0,
      behind_count = 0,
      has_upstream = false,
    }
  end

  local git_output = vim.fn.systemlist({
    "git",
    "-C",
    directory_path,
    "rev-list",
    "--left-right",
    "--count",
    "@{upstream}...HEAD",
  })[1]

  if vim.v.shell_error ~= 0 or not git_output or git_output == "" then
    return {
      ahead_count = 0,
      behind_count = 0,
      has_upstream = true,
    }
  end

  local behind_count_string, ahead_count_string = git_output:match("^(%d+)%s+(%d+)$")

  return {
    ahead_count = tonumber(ahead_count_string) or 0,
    behind_count = tonumber(behind_count_string) or 0,
    has_upstream = true,
  }
end

local function get_repository_status(directory_path)
  local sync_status = get_git_sync_status(directory_path)
  local status_parts = {}

  if has_git_changes(directory_path) then
    table.insert(status_parts, "●")
  end

  if sync_status.ahead_count > 0 then
    table.insert(status_parts, "↑" .. sync_status.ahead_count)
  end

  if sync_status.behind_count > 0 then
    table.insert(status_parts, "↓" .. sync_status.behind_count)
  end

  if not sync_status.has_upstream then
    table.insert(status_parts, "?")
  end

  return table.concat(status_parts, " ")
end

local function collect_git_repositories(root_directory_path)
  local repositories = {}

  for child_name, child_type in vim.fs.dir(root_directory_path) do
    if child_type == "directory" and child_name ~= ".git" and child_name ~= "node_modules" then
      local child_directory_path = vim.fs.joinpath(root_directory_path, child_name)

      if is_git_repository(child_directory_path) then
        table.insert(repositories, {
          branch = get_git_branch(child_directory_path),
          name = child_name,
          path = child_directory_path,
          status = get_repository_status(child_directory_path),
        })
      end
    end
  end

  table.sort(repositories, function(left_repository, right_repository)
    return left_repository.name < right_repository.name
  end)

  return repositories
end

local function open_repositories_popup()
  local repositories = collect_git_repositories(vim.uv.cwd())

  if #repositories == 0 then
    vim.notify("В текущей папке не найдено репозиториев", vim.log.levels.INFO)
    return
  end

  local repository_buffer_lines = {}
  local maximum_repository_line_width = 0

  for repository_index, repository in ipairs(repositories) do
    local repository_line = string.format("%d. %s [%s]", repository_index, repository.name, repository.branch)

    if repository.status ~= "" then
      repository_line = repository_line .. " " .. repository.status
    end

    maximum_repository_line_width = math.max(maximum_repository_line_width, vim.fn.strdisplaywidth(repository_line))
    table.insert(repository_buffer_lines, repository_line)
  end

  local current_window_number = vim.api.nvim_get_current_win()
  local repository_buffer_number = vim.api.nvim_create_buf(false, true)
  local repository_window_height = math.min(math.max(#repository_buffer_lines, 8), 18)
  local repository_window_width = math.min(
    math.max(maximum_repository_line_width + 6, 60),
    math.floor(vim.o.columns * 0.75)
  )
  local repository_window_row = math.floor((vim.o.lines - repository_window_height) / 2) - 1
  local repository_window_column = math.floor((vim.o.columns - repository_window_width) / 2)

  vim.api.nvim_buf_set_lines(repository_buffer_number, 0, -1, false, repository_buffer_lines)

  vim.bo[repository_buffer_number].buftype = "nofile"
  vim.bo[repository_buffer_number].bufhidden = "wipe"
  vim.bo[repository_buffer_number].swapfile = false
  vim.bo[repository_buffer_number].modifiable = false
  vim.bo[repository_buffer_number].filetype = "repositories_list"

  local repository_window_number = vim.api.nvim_open_win(repository_buffer_number, true, {
    relative = "editor",
    row = math.max(repository_window_row, 1),
    col = math.max(repository_window_column, 0),
    width = repository_window_width,
    height = repository_window_height,
    style = "minimal",
    border = "rounded",
    title = " Repositories ",
    title_pos = "center",
  })

  vim.wo[repository_window_number].number = false
  vim.wo[repository_window_number].relativenumber = false
  vim.wo[repository_window_number].cursorline = true
  vim.wo[repository_window_number].signcolumn = "no"
  vim.wo[repository_window_number].wrap = false
  vim.wo[repository_window_number].winblend = 0

  local function close_repository_window()
    if vim.api.nvim_win_is_valid(repository_window_number) then
      vim.api.nvim_win_close(repository_window_number, true)
    end

    if vim.api.nvim_win_is_valid(current_window_number) then
      vim.api.nvim_set_current_win(current_window_number)
    end
  end

  local function select_repository()
    local cursor_line_number = vim.api.nvim_win_get_cursor(repository_window_number)[1]
    local selected_repository = repositories[cursor_line_number]

    if not selected_repository then
      return
    end

    close_repository_window()
    vim.cmd("cd " .. vim.fn.fnameescape(selected_repository.path))
    vim.notify("Текущий репозиторий: " .. selected_repository.name, vim.log.levels.INFO)
  end

  vim.keymap.set("n", "q", close_repository_window, { buffer = repository_buffer_number, silent = true })
  vim.keymap.set("n", "<Esc>", close_repository_window, { buffer = repository_buffer_number, silent = true })
  vim.keymap.set("n", "<CR>", select_repository, { buffer = repository_buffer_number, silent = true })

  vim.api.nvim_win_set_cursor(repository_window_number, { 1, 0 })
end

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
          require("telescope.builtin").oldfiles({
            cwd = vim.uv.cwd(),
          })
        end,
        desc = "Recent Files (cwd)",
      },
      {
        "<leader>fR",
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
      {
        "<leader>fG",
        open_repositories_popup,
        desc = "Repositories",
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
