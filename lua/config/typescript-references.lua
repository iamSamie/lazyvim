local module = {}

local group = vim.api.nvim_create_augroup("user_typescript_references", { clear = true })

local typescript_filetypes = {
  javascript = true,
  javascriptreact = true,
  typescript = true,
  typescriptreact = true,
}

local typescript_lsp_client_names = {
  ts_ls = true,
  tsserver = true,
  vtsls = true,
}

local function show_default_references()
  Snacks.picker.lsp_references()
end

local function show_typescript_grep_references()
  local current_word = vim.fn.expand("<cword>")

  if current_word == "" then
    show_default_references()
    return
  end

  vim.notify("LSP references not found, using grep fallback", vim.log.levels.INFO)

  Snacks.picker.grep({
    search = current_word,
    regex = false,
    args = { "--word-regexp" },
    glob = { "*.ts", "*.tsx", "*.js", "*.jsx" },
  })
end

local function get_typescript_lsp_client(buffer_number, method_name)
  for _, lsp_client in ipairs(vim.lsp.get_clients({ bufnr = buffer_number })) do
    if typescript_lsp_client_names[lsp_client.name] and lsp_client.supports_method(method_name) then
      return lsp_client
    end
  end

  return nil
end

local function normalize_lsp_location(location_result)
  if not location_result then
    return nil
  end

  if vim.tbl_islist(location_result) then
    return location_result[1]
  end

  return location_result
end

local function open_reference_picker(reference_locations, offset_encoding)
  local reference_items = vim.lsp.util.locations_to_items(reference_locations, offset_encoding)

  if #reference_items == 0 then
    return
  end

  Snacks.picker.pick({
    title = "LSP References",
    items = vim.tbl_map(function(reference_item)
      return {
        file = reference_item.filename,
        pos = { reference_item.lnum, reference_item.col },
        text = reference_item.text,
      }
    end, reference_items),
    format = "file",
    focus = "list",
    auto_confirm = true,
    jump = { tagstack = true, reuse_win = true },
  })
end

function module.open()
  local current_buffer_number = vim.api.nvim_get_current_buf()

  if not typescript_filetypes[vim.bo[current_buffer_number].filetype] then
    show_default_references()
    return
  end

  local references_client = get_typescript_lsp_client(current_buffer_number, "textDocument/references")
  local type_definition_client = get_typescript_lsp_client(current_buffer_number, "textDocument/typeDefinition")

  if not references_client then
    show_typescript_grep_references()
    return
  end

  local reference_params = vim.lsp.util.make_position_params(0, references_client.offset_encoding)
  reference_params.context = { includeDeclaration = false }

  references_client.request("textDocument/references", reference_params, function(reference_error, reference_result)
    if reference_error then
      vim.schedule(show_typescript_grep_references)
      return
    end

    if reference_result and not vim.tbl_isempty(reference_result) then
      vim.schedule(function()
        open_reference_picker(reference_result, references_client.offset_encoding)
      end)
      return
    end

    if not type_definition_client then
      vim.schedule(show_typescript_grep_references)
      return
    end

    local type_definition_params = vim.lsp.util.make_position_params(0, type_definition_client.offset_encoding)

    type_definition_client.request("textDocument/typeDefinition", type_definition_params, function(type_definition_error, type_definition_result)
      if type_definition_error then
        vim.schedule(show_typescript_grep_references)
        return
      end

      local target_location = normalize_lsp_location(type_definition_result)
      local target_uri = target_location and (target_location.uri or target_location.targetUri)
      local target_range = target_location and (target_location.range or target_location.targetSelectionRange or target_location.targetRange)

      if not (target_uri and target_range) then
        vim.schedule(show_typescript_grep_references)
        return
      end

      references_client.request("textDocument/references", {
        textDocument = { uri = target_uri },
        position = target_range.start,
        context = { includeDeclaration = false },
      }, function(fallback_error, fallback_result)
        if fallback_error or not fallback_result or vim.tbl_isempty(fallback_result) then
          vim.schedule(show_typescript_grep_references)
          return
        end

        vim.schedule(function()
          open_reference_picker(fallback_result, references_client.offset_encoding)
        end)
      end, current_buffer_number)
    end, current_buffer_number)
  end, current_buffer_number)
end

local function set_buffer_reference_keymap(buffer_number)
  if not typescript_filetypes[vim.bo[buffer_number].filetype] then
    return
  end

  vim.keymap.set("n", "gr", module.open, {
    buffer = buffer_number,
    desc = "TS References",
    nowait = true,
    silent = true,
  })
end

local function defer_set_buffer_reference_keymap(buffer_number)
  local delays = { 0, 20, 100, 300 }

  for _, delay in ipairs(delays) do
    vim.defer_fn(function()
      if vim.api.nvim_buf_is_valid(buffer_number) and vim.api.nvim_buf_is_loaded(buffer_number) then
        set_buffer_reference_keymap(buffer_number)
      end
    end, delay)
  end
end

function module.setup()
  vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    callback = function(args)
      defer_set_buffer_reference_keymap(args.buf)
    end,
  })
end

return module
