return {
  {
    "saghen/blink.cmp",
    opts = function(_, opts)
      opts.keymap = opts.keymap or {}
      opts.keymap["<D-Space>"] = {
        function(cmp)
          return cmp.show({ providers = { "lsp" } })
        end,
        "show_documentation",
        "hide_documentation",
      }
    end,
  },
}
