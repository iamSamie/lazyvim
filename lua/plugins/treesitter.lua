return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.auto_install = true
      opts.ensure_installed = opts.ensure_installed or {}

      if not vim.tbl_contains(opts.ensure_installed, "gotmpl") then
        table.insert(opts.ensure_installed, "gotmpl")
      end
    end,
  },
}
