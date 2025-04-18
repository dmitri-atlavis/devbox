local map = vim.api.nvim_set_keymap

vim.o.guicursor = 'n-v-c-sm:block-Cursor-blinkwait175-blinkoff150-blinkon175,i-ci-ve:ver25,r-cr-o:hor20'
vim.o.tabstop = 4 -- A TAB character looks like 4 spaces
vim.o.expandtab = true -- Pressing the TAB key will insert spaces instead of a TAB character
vim.o.softtabstop = 4 -- Number of spaces inserted instead of a TAB character
vim.o.shiftwidth = 4 -- Number of spaces inserted when indenting

-- Mapping from plugins
map('n', '<C-g>', '<CMD>GitBlameToggle<CR>', { desc = 'Git blame' })

-- Buffers
map('n', '<C-x>', '<CMD>bd<CR>', { desc = 'Delete buffer' })
map('n', '<C-x><C-a>', '<CMD>%bd<CR>', { desc = 'Delete all buffers' })
map('n', '<C-q>', '<CMD>%bd|e#<CR>', { desc = 'Delete all buffers except this one' })
map(
  'n',
  '<Leader><Leader>',
  ':lua require("telescope.builtin").buffers({ sort_lastused = true, ignore_current_buffer = true, initial_mode="normal" })<CR>',
  { desc = 'Open Buffers' }
)

-- File System
map('n', '\\', '<CMD>Neotree<CR>', { desc = 'Neotree' })
map('n', '-', '<CMD>Oil --float<CR>', { desc = 'Open directory' })
map('n', '<Leader>sF', ':lua require("telescope.builtin").find_files({ hidden = true })<CR>', { desc = '[S]earch Hidden [F]iles' })

-- Disable tree-sitter for Dockerfiles
require('nvim-treesitter.configs').setup {
  highlight = {
    enable = true,
    disable = { 'dockerfile' },
  },
}
