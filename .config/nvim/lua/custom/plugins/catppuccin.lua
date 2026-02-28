return {
  'catppuccin/nvim',
  name = 'catppuccin',
  priority = 1000,
  opts = {
    integrations = {
      snacks = true,
    },
    custom_highlights = function(colors)
      return {
        NormalFloat = { bg = colors.base },
        FloatBorder = { bg = colors.base },
        SnacksExplorerNormal = { bg = colors.base },
        SnacksPicker = { bg = colors.base },
        SnacksPickerBorder = { bg = colors.base },
      }
    end,
  },
  config = function(_, opts)
    require('catppuccin').setup(opts)
    vim.cmd.colorscheme 'catppuccin'
  end,
}
