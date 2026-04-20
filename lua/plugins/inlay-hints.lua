local group = vim.api.nvim_create_augroup("user_inlay_hints", { clear = true })

local ts_filetypes = {
  javascript = true,
  javascriptreact = true,
  typescript = true,
  typescriptreact = true,
}

local function enable_inlay_hints(bufnr)
  if not vim.lsp.inlay_hint or not vim.lsp.inlay_hint.enable then
    return
  end

  if not ts_filetypes[vim.bo[bufnr].filetype] then
    return
  end

  vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
end

return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}

      local inlay_hints = {
        parameterNames = {
          enabled = "all",
          suppressWhenArgumentMatchesName = false,
        },
        parameterTypes = { enabled = true },
        variableTypes = { enabled = false },
        propertyDeclarationTypes = { enabled = true },
        functionLikeReturnTypes = { enabled = false },
        enumMemberValues = { enabled = true },
      }

      opts.servers.tsserver = vim.tbl_deep_extend("force", opts.servers.tsserver or {}, {
        settings = {
          javascript = { inlayHints = inlay_hints },
          typescript = { inlayHints = inlay_hints },
        },
      })

      opts.servers.ts_ls = vim.tbl_deep_extend("force", opts.servers.ts_ls or {}, {
        settings = {
          javascript = { inlayHints = inlay_hints },
          typescript = { inlayHints = inlay_hints },
        },
      })

      opts.servers.vtsls = vim.tbl_deep_extend("force", opts.servers.vtsls or {}, {
        settings = {
          javascript = { inlayHints = inlay_hints },
          typescript = { inlayHints = inlay_hints },
        },
      })
    end,
    init = function()
      vim.api.nvim_create_autocmd("LspAttach", {
        group = group,
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and client.supports_method("textDocument/inlayHint") then
            enable_inlay_hints(args.buf)
          end
        end,
      })

      vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
        group = group,
        callback = function(args)
          enable_inlay_hints(args.buf)
        end,
      })
    end,
  },
}
