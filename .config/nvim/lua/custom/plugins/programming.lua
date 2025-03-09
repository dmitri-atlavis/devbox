return {
  'nvimtools/none-ls.nvim',
  dependencies = {
    'nvimtools/none-ls-extras.nvim',
    'jayp0521/mason-null-ls.nvim',
  },

  config = function()
    require('mason-null-ls').setup {
      ensure_installed = {
        'ruff', -- python linter (formatter & more, except type checking)
        'pyright', -- python type checkers
        'prettier', -- for non python formatting
        'shfmt', -- for shell scripts formatting
      },
      automatic_installation = true,
    }

    local null_ls = require 'null-ls'
    local sources = {
      require('none-ls.formatting.ruff').with { extra_args = { '--select', 'I' } },
      require 'none-ls.formatting.ruff_format',
      null_ls.builtins.formatting.prettier.with { filetypes = { 'json', 'yaml', 'markdown' } },
      null_ls.builtins.formatting.shfmt.with { args = { '-i', '4' } },
    }

    null_ls.setup {
      sources = sources,
    }

    -- disable pyright formatting and imports organization
    require('lspconfig').pyright.setup {
      settings = {
        pyright = {
          -- Using Ruff's import organizer
          disableOrganizeImports = true,
        },
      },
    }
  end,
}
