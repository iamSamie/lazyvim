local function is_package_json(buffer_number)
  local buffer_name = vim.api.nvim_buf_get_name(buffer_number)
  return vim.fn.fnamemodify(buffer_name, ":t") == "package.json"
end

local function is_makefile(buffer_number)
  local buffer_name = vim.api.nvim_buf_get_name(buffer_number)
  local file_name = vim.fn.fnamemodify(buffer_name, ":t")
  return file_name == "Makefile" or file_name == "makefile" or file_name == "GNUmakefile" or file_name:match("%.mk$")
end

local function find_package_script_name(line_text)
  return line_text:match('^%s*"([^"]+)"%s*:%s*".-"%s*,?%s*$')
end

local function find_make_target_name(line_text)
  if line_text:match("^%s*#") or line_text:match("^%s*$") or line_text:match("^\t") then
    return nil
  end

  local target_name = line_text:match("^([%w%._%/%-]+)%s*:")
  if not target_name or target_name:sub(1, 1) == "." then
    return nil
  end

  return target_name
end

local function collect_package_script_lines(buffer_number)
  local buffer_lines = vim.api.nvim_buf_get_lines(buffer_number, 0, -1, false)
  local script_line_numbers = {}
  local is_inside_scripts_object = false
  local object_depth = 0

  for line_index, line_text in ipairs(buffer_lines) do
    if not is_inside_scripts_object then
      if line_text:match('"scripts"%s*:%s*{') then
        is_inside_scripts_object = true
        object_depth = 1
      end
    else
      local script_name = find_package_script_name(line_text)
      if script_name then
        table.insert(script_line_numbers, line_index)
      end

      local opening_braces_count = select(2, line_text:gsub("{", ""))
      local closing_braces_count = select(2, line_text:gsub("}", ""))
      object_depth = object_depth + opening_braces_count - closing_braces_count

      if object_depth <= 0 then
        break
      end
    end
  end

  return script_line_numbers
end

local function collect_make_target_lines(buffer_number)
  local buffer_lines = vim.api.nvim_buf_get_lines(buffer_number, 0, -1, false)
  local target_line_numbers = {}

  for line_index, line_text in ipairs(buffer_lines) do
    if find_make_target_name(line_text) then
      table.insert(target_line_numbers, line_index)
    end
  end

  return target_line_numbers
end

local function detect_package_manager(project_root)
  if vim.uv.fs_stat(project_root .. "/pnpm-lock.yaml") then
    return "pnpm"
  end

  if vim.uv.fs_stat(project_root .. "/yarn.lock") then
    return "yarn"
  end

  return "npm"
end

local function run_command_in_terminal(command_to_run, project_root)
  local escaped_command = command_to_run:gsub("\\", "\\\\"):gsub('"', '\\"')
  local escaped_directory = vim.fn.fnameescape(project_root)
  local executed_with_toggleterm = pcall(vim.cmd, 'TermExec cmd="' .. escaped_command .. '" dir=' .. escaped_directory)

  if executed_with_toggleterm then
    return
  end

  vim.cmd("botright split")
  vim.cmd("resize 15")
  vim.cmd("terminal " .. command_to_run)
  vim.cmd("startinsert")
end

local function run_target_under_cursor()
  local buffer_number = vim.api.nvim_get_current_buf()
  local current_line_text = vim.api.nvim_get_current_line()
  local project_root = LazyVim and LazyVim.root() or vim.fn.getcwd()

  if is_package_json(buffer_number) then
    local script_name = find_package_script_name(current_line_text)
    if not script_name then
      vim.notify("Place cursor on a script line in package.json", vim.log.levels.WARN)
      return
    end

    local package_manager = detect_package_manager(project_root)
    local command_to_run = package_manager == "yarn"
      and ("yarn " .. script_name)
      or (package_manager .. " run " .. script_name)

    run_command_in_terminal(command_to_run, project_root)
    return
  end

  if is_makefile(buffer_number) then
    local target_name = find_make_target_name(current_line_text)
    if not target_name then
      vim.notify("Place cursor on a Make target line", vim.log.levels.WARN)
      return
    end

    run_command_in_terminal("make " .. target_name, project_root)
    return
  end

  vim.notify("Run signs are available in package.json and Makefiles", vim.log.levels.INFO)
end

local function place_run_signs(buffer_number)
  vim.fn.sign_unplace("run_signs", { buffer = buffer_number })

  local line_numbers = {}
  if is_package_json(buffer_number) then
    line_numbers = collect_package_script_lines(buffer_number)
  elseif is_makefile(buffer_number) then
    line_numbers = collect_make_target_lines(buffer_number)
  end

  for _, line_number in ipairs(line_numbers) do
    vim.fn.sign_place(0, "run_signs", "RunCommandSign", buffer_number, {
      lnum = line_number,
      priority = 12,
    })
  end
end

return {
  {
    "akinsho/toggleterm.nvim",
    opts = function()

      vim.fn.sign_define("RunCommandSign", {
        text = "▶",
        texthl = "DiagnosticHint",
        numhl = "DiagnosticHint",
      })

      local run_signs_group = vim.api.nvim_create_augroup("user_run_signs", { clear = true })
      vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "TextChanged", "TextChangedI", "BufEnter", "FileType" }, {
        group = run_signs_group,
        pattern = { "package.json", "Makefile", "makefile", "GNUmakefile", "*.mk" },
        callback = function(autocmd_args)
          place_run_signs(autocmd_args.buf)
        end,
      })

      vim.schedule(function()
        for _, buffer_number in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_loaded(buffer_number) then
            place_run_signs(buffer_number)
          end
        end
      end)

      vim.keymap.set("n", "<leader>rs", run_target_under_cursor, {
        desc = "Run Script or Make Target",
      })
    end,
  },
}
