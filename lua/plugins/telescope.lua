local repository_status_namespace = vim.api.nvim_create_namespace("repository_status_highlights")

local function set_repository_status_highlights()
  vim.api.nvim_set_hl(0, "RepositoryStatusChanges", { fg = "#e0af68" })
  vim.api.nvim_set_hl(0, "RepositoryStatusAhead", { fg = "#9ece6a" })
  vim.api.nvim_set_hl(0, "RepositoryStatusBehind", { fg = "#7dcfff" })
  vim.api.nvim_set_hl(0, "RepositoryStatusNoUpstream", { fg = "#f7768e" })
end

set_repository_status_highlights()

vim.api.nvim_create_autocmd("ColorScheme", {
  callback = set_repository_status_highlights,
})

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

local function create_floating_window(window_buffer_number, window_options)
  local floating_window_number = vim.api.nvim_open_win(window_buffer_number, true, {
    relative = "editor",
    row = window_options.row,
    col = window_options.col,
    width = window_options.width,
    height = window_options.height,
    style = "minimal",
    border = "rounded",
    title = window_options.title,
    title_pos = "center",
  })

  vim.wo[floating_window_number].number = false
  vim.wo[floating_window_number].relativenumber = false
  vim.wo[floating_window_number].cursorline = true
  vim.wo[floating_window_number].signcolumn = "no"
  vim.wo[floating_window_number].wrap = false
  vim.wo[floating_window_number].winblend = 0

  return floating_window_number
end

local function apply_repository_status_highlights(buffer_number, repositories)
  vim.api.nvim_buf_clear_namespace(buffer_number, repository_status_namespace, 0, -1)

  for repository_index, repository in ipairs(repositories) do
    if repository.status ~= "" then
      local repository_prefix = string.format("%d. %s [%s] ", repository_index, repository.name, repository.branch)
      local status_column = vim.fn.strchars(repository_prefix)

      for status_part in repository.status:gmatch("%S+") do
        local status_highlight = nil

        if status_part == "●" then
          status_highlight = "RepositoryStatusChanges"
        elseif vim.startswith(status_part, "↑") then
          status_highlight = "RepositoryStatusAhead"
        elseif vim.startswith(status_part, "↓") then
          status_highlight = "RepositoryStatusBehind"
        elseif status_part == "?" then
          status_highlight = "RepositoryStatusNoUpstream"
        end

        if status_highlight then
          vim.api.nvim_buf_add_highlight(
            buffer_number,
            repository_status_namespace,
            status_highlight,
            repository_index - 1,
            status_column,
            status_column + vim.fn.strchars(status_part)
          )
        end

        status_column = status_column + vim.fn.strchars(status_part) + 1
      end
    end
  end
end

local function open_repository_lazygit(repository, on_close)
  local terminal_module = require("toggleterm.terminal")
  local lazygit_terminal = terminal_module.Terminal:new({
    close_on_exit = true,
    cmd = "lazygit",
    direction = "float",
    dir = repository.path,
    hidden = true,
    on_close = function()
      if on_close then
        vim.schedule(on_close)
      end
    end,
  })

  lazygit_terminal:toggle()
end

local function open_repositories_popup()
  local root_directory_path = vim.uv.cwd()
  local repositories = collect_git_repositories(root_directory_path)

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

  local browser_state = {
    current_window_number = vim.api.nvim_get_current_win(),
    repository_buffer_number = vim.api.nvim_create_buf(false, true),
    repository_window_number = nil,
    repositories = repositories,
  }

  vim.bo[browser_state.repository_buffer_number].buftype = "nofile"
  vim.bo[browser_state.repository_buffer_number].bufhidden = "wipe"
  vim.bo[browser_state.repository_buffer_number].swapfile = false
  vim.bo[browser_state.repository_buffer_number].modifiable = true
  vim.bo[browser_state.repository_buffer_number].filetype = "repositories_list"
  vim.api.nvim_buf_set_lines(browser_state.repository_buffer_number, 0, -1, false, repository_buffer_lines)
  vim.bo[browser_state.repository_buffer_number].modifiable = false
  apply_repository_status_highlights(browser_state.repository_buffer_number, repositories)

  local repository_window_height = math.min(math.max(#repository_buffer_lines, 8), 18)
  local repository_window_width = math.min(
    math.max(maximum_repository_line_width + 6, 60),
    math.floor(vim.o.columns * 0.75)
  )
  local repository_window_row = math.floor((vim.o.lines - repository_window_height) / 2) - 1
  local repository_window_column = math.floor((vim.o.columns - repository_window_width) / 2)

  browser_state.repository_window_number = create_floating_window(browser_state.repository_buffer_number, {
    col = math.max(repository_window_column, 0),
    height = repository_window_height,
    row = math.max(repository_window_row, 1),
    title = " Repositories ",
    width = repository_window_width,
  })

  local function close_browser()
    if browser_state.repository_window_number and vim.api.nvim_win_is_valid(browser_state.repository_window_number) then
      vim.api.nvim_win_close(browser_state.repository_window_number, true)
    end

    if browser_state.repository_buffer_number and vim.api.nvim_buf_is_valid(browser_state.repository_buffer_number) then
      vim.api.nvim_buf_delete(browser_state.repository_buffer_number, { force = true })
    end

    if browser_state.current_window_number and vim.api.nvim_win_is_valid(browser_state.current_window_number) then
      vim.api.nvim_set_current_win(browser_state.current_window_number)
    end
  end

  local function open_selected_repository_lazygit()
    local cursor_line_number = vim.api.nvim_win_get_cursor(browser_state.repository_window_number)[1]
    local selected_repository = browser_state.repositories[cursor_line_number]

    if not selected_repository then
      return
    end

    close_browser()

    open_repository_lazygit(selected_repository, function()
      vim.cmd("cd " .. vim.fn.fnameescape(root_directory_path))

      if vim.api.nvim_get_mode().mode ~= "c" then
        open_repositories_popup()
      end
    end)
  end

  vim.keymap.set("n", "q", close_browser, { buffer = browser_state.repository_buffer_number, silent = true })
  vim.keymap.set("n", "<Esc>", close_browser, { buffer = browser_state.repository_buffer_number, silent = true })
  vim.keymap.set("n", "<CR>", open_selected_repository_lazygit, { buffer = browser_state.repository_buffer_number, silent = true })

  vim.api.nvim_win_set_cursor(browser_state.repository_window_number, { 1, 0 })
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
