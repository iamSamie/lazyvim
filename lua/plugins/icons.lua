return {
  {
    "nvim-mini/mini.icons",
    lazy = false,
    priority = 1000,
    config = function()
      require("mini.icons").setup({ style = "glyph" })
      MiniIcons.mock_nvim_web_devicons()
    end,
  },
}
