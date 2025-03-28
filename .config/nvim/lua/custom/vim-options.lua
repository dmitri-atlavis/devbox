local map = vim.api.nvim_set_keymap
local map_opts = { noremap = true, silent = true }

vim.o.guicursor = 'n-v-c-sm:block-Cursor-blinkwait175-blinkoff150-blinkon175,i-ci-ve:ver25,r-cr-o:hor20'
vim.o.tabstop = 4 -- A TAB character looks like 4 spaces
vim.o.expandtab = true -- Pressing the TAB key will insert spaces instead of a TAB character
vim.o.softtabstop = 4 -- Number of spaces inserted instead of a TAB character
vim.o.shiftwidth = 4 -- Number of spaces inserted when indenting

-- Git blame
map('n', '<C-g>', '<CMD>GitBlameToggle<CR>', map_opts)
map('n', '-', '<CMD>Oil --float<CR>', { desc = 'Open directory' })
map('n', '<Leader>sb', '<CMD>Telescope file_browser<CR>', map_opts)
map('n', '<Leader>s,', ':lua require"telescope.builtin".find_files({ hidden = true })<CR>', { noremap = true, silent = true })
