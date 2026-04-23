return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.auto_install = true
      opts.ensure_installed = opts.ensure_installed or {}
    end,
  },
}
