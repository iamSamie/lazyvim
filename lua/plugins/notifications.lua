return {
  {
    "folke/noice.nvim",
    opts = {
      notify = {
        enabled = true,
        view = "notify",
        replace = false,
        merge = false,
      },
      lsp = {
        progress = {
          enabled = false,
        },
      },
      cmdline = {
        format = {
          search_down = {
            view = "search_popup_top",
          },
          search_up = {
            view = "search_popup_top",
          },
        },
      },
      views = {
        mini = {
          timeout = 7000,
        },
        search_popup_top = {
          backend = "popup",
          relative = "editor",
          position = {
            row = 2,
            col = "60%",
          },
          size = {
            width = "60%",
            height = "auto",
          },
          border = {
            style = "rounded",
          },
        },
      },
    },
    config = function(_, opts)
      require("noice").setup(opts)

      local function set_noice_highlights()
        vim.api.nvim_set_hl(0, "NoiceMini", { bg = "#2a2f3a" })
        vim.api.nvim_set_hl(0, "NoiceMiniTitle", { bg = "#2a2f3a" })
      end

      set_noice_highlights()

      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = set_noice_highlights,
      })

      local progress_by_client = vim.defaulttable(function()
        return {}
      end)

      vim.api.nvim_create_autocmd("LspProgress", {
        callback = function(event)
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          local progress_value = event.data.params.value

          if not client or type(progress_value) ~= "table" then
            return
          end

          local client_progress_list = progress_by_client[client.id]

          for progress_index = 1, #client_progress_list + 1 do
            if progress_index == #client_progress_list + 1 or client_progress_list[progress_index].token == event.data.params.token then
              client_progress_list[progress_index] = {
                token = event.data.params.token,
                message = ("%s%s"):format(
                  progress_value.title or "",
                  progress_value.message and (" %s"):format(progress_value.message) or ""
                ),
                done = progress_value.kind == "end",
              }
              break
            end
          end

          local message_lines = {}

          progress_by_client[client.id] = vim.tbl_filter(function(progress_item)
            if progress_item.message ~= "" then
              table.insert(message_lines, progress_item.message)
            end

            return not progress_item.done
          end, client_progress_list)

          if #message_lines == 0 then
            vim.notify("Done", vim.log.levels.INFO, {
              id = "lsp_progress_" .. client.id,
              title = client.name,
              timeout = 1500,
            })
            return
          end

          vim.notify(table.concat(message_lines, "\n"), vim.log.levels.INFO, {
            id = "lsp_progress_" .. client.id,
            title = client.name,
            timeout = 7000,
          })
        end,
      })
    end,
  },
  {
    "snacks.nvim",
    opts = {
      notifier = {
        enabled = true,
        timeout = 7000,
        width = { min = 80, max = 80 },
        margin = { top = 0, right = 1, bottom = 2 },
        padding = true,
        gap = 1,
        top_down = false,
        style = "compact",
      },
    },
  },
}
