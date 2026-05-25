local git_status_cache = {}

local function get_git_status(file_path)
  if type(file_path) ~= "string" or file_path == "" then
    return nil
  end

  if git_status_cache[file_path] ~= nil then
    return git_status_cache[file_path] or nil
  end

  local file_directory = vim.fn.fnamemodify(file_path, ":h")
  local git_status = vim.fn.systemlist({
    "git",
    "-C",
    file_directory,
    "status",
    "--porcelain",
    "--",
    file_path,
  })[1]

  local status = false

  if git_status then
    local status_code = git_status:sub(1, 2)

    if status_code == "??" or status_code:match("A") then
      status = "new"
    elseif status_code:match("[MDRCU]") then
      status = "modified"
    end
  end

  git_status_cache[file_path] = status

  return status or nil
end

local function clear_git_status_cache()
  git_status_cache = {}
  pcall(vim.cmd, "BufferLineRefresh")
end

local function set_git_status_highlights()
  vim.api.nvim_set_hl(0, "BufferLineGitModifiedMarker", { fg = "#ff9e64" })
  vim.api.nvim_set_hl(0, "BufferLineGitNewMarker", { fg = "#f5c2e7" })
end

vim.api.nvim_create_autocmd({
  "BufEnter",
  "BufWritePost",
  "FocusGained",
}, {
  callback = clear_git_status_cache,
})

vim.api.nvim_create_autocmd("ColorScheme", {
  callback = set_git_status_highlights,
})

set_git_status_highlights()

return {
  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      options = {
        always_show_bufferline = true,
        custom_filter = function(buffer_number)
          local buffer_name = vim.api.nvim_buf_get_name(buffer_number)

          return not vim.startswith(buffer_name, "git://HEAD/")
        end,
        diagnostics = "nvim_lsp",
        offsets = {
          {
            filetype = "neo-tree",
            text = "Explorer",
            highlight = "Directory",
            text_align = "left",
          },
        },
      },
    },
    config = function(_, opts)
      local bufferline_ui = require("bufferline.ui")
      local original_element = bufferline_ui.element

      bufferline_ui.element = function(current_state, element)
        local rendered_element = original_element(current_state, element)
        local git_status = get_git_status(rendered_element.path)

        if not git_status then
          return rendered_element
        end

        local marker_highlight = "BufferLineGitModifiedMarker"

        if git_status == "new" then
          marker_highlight = "BufferLineGitNewMarker"
        end

        local original_component = rendered_element.component

        rendered_element.component = function(next_item)
          local component = original_component(next_item)

          for component_index, component_part in ipairs(component) do
            if component_part.attr and component_part.attr.__id == bufferline_ui.components.id.name then
              table.insert(component, component_index + 1, {
                text = " ●",
                highlight = marker_highlight,
              })
              break
            end
          end

          return component
        end

        rendered_element.length = rendered_element.length + 2

        return rendered_element
      end

      require("bufferline").setup(opts)
    end,
  },
}
