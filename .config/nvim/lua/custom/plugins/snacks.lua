return {
  'folke/snacks.nvim',
  lazy = false,
  priority = 1000,
  ---@type snacks.Config
  opts = {
    picker = { enabled = true },
    explorer = { enabled = true },
    lazygit = { enabled = true },
  },
  keys = {
    -- Search
    { '<leader>sh', function() Snacks.picker.help() end, desc = '[S]earch [H]elp' },
    { '<leader>sk', function() Snacks.picker.keymaps() end, desc = '[S]earch [K]eymaps' },
    { '<leader>sf', function() Snacks.picker.files() end, desc = '[S]earch [F]iles' },
    { '<leader>sF', function() Snacks.picker.files { hidden = true } end, desc = '[S]earch Hidden [F]iles' },
    { '<leader>sg', function() Snacks.picker.grep() end, desc = '[S]earch by [G]rep' },
    { '<leader>sd', function() Snacks.picker.diagnostics() end, desc = '[S]earch [D]iagnostics' },
    { '<leader>sr', function() Snacks.picker.resume() end, desc = '[S]earch [R]esume' },
    { '<leader>s.', function() Snacks.picker.recent() end, desc = '[S]earch Recent Files ("." for repeat)' },
    { '<leader>s/', function() Snacks.picker.grep_buffers() end, desc = '[S]earch [/] in Open Files' },
    { '<leader>sn', function() Snacks.picker.files { cwd = vim.fn.stdpath 'config' } end, desc = '[S]earch [N]eovim files' },
    { '<leader>sw', function() Snacks.picker.grep_word() end, desc = '[S]earch current [W]ord', mode = { 'n', 'v' } },
    { '<leader>ss', function() Snacks.picker.lsp_symbols() end, desc = '[S]earch LSP [S]ymbols' },
    { '<leader><leader>', function() Snacks.picker.buffers { sort_lastused = true, current = false } end, desc = '[ ] Find existing buffers' },
    { '<leader>/', function() Snacks.picker.lines() end, desc = '[/] Fuzzily search in current buffer' },

    -- LSP
    { 'gd', function() Snacks.picker.lsp_definitions() end, desc = '[G]oto [D]efinition' },
    { 'gr', function() Snacks.picker.lsp_references() end, desc = '[G]oto [R]eferences' },
    { 'gI', function() Snacks.picker.lsp_implementations() end, desc = '[G]oto [I]mplementation' },
    { '<leader>D', function() Snacks.picker.lsp_type_definitions() end, desc = 'Type [D]efinition' },
    { '<leader>ds', function() Snacks.picker.lsp_document_symbols() end, desc = '[D]ocument [S]ymbols' },
    { '<leader>ws', function() Snacks.picker.lsp_workspace_symbols() end, desc = '[W]orkspace [S]ymbols' },

    -- Explorer
    { '\\', function() Snacks.explorer() end, desc = 'File Explorer' },
    { '<leader>e', function() Snacks.explorer() end, desc = 'File Explorer' },

    -- Lazygit
    { '<leader>g', function() Snacks.lazygit() end, desc = 'LazyGit' },
  },
}
