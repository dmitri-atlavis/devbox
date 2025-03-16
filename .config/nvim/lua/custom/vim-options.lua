local map = vim.api.nvim_set_keymap
local map_opts = { noremap = true, silent = true }

--
-- Buffers Controls
--

-- Switch to previous/next
map('n', '<C-A-h>', '<Cmd>BufferPrevious<CR>', map_opts)
map('n', '<C-A-l>', '<Cmd>BufferNext<CR>', map_opts)

-- Move back/forth
map('n', '<C-A-j>', '<Cmd>BufferMovePrevious<CR>', map_opts)
map('n', '<C-A-k>', '<Cmd>BufferMoveNext<CR>', map_opts)

-- Close buffer
map('n', '<C-q>', '<Cmd>BufferClose<CR>', map_opts)
map('n', '<C-x>', '<Cmd>BufferCloseAllButCurrent<CR>', map_opts)

vim.o.guicursor = 'n-v-c-sm:block-Cursor-blinkwait175-blinkoff150-blinkon175,i-ci-ve:ver25,r-cr-o:hor20'
vim.o.tabstop = 4 -- A TAB character looks like 4 spaces
vim.o.expandtab = true -- Pressing the TAB key will insert spaces instead of a TAB character
vim.o.softtabstop = 4 -- Number of spaces inserted instead of a TAB character
vim.o.shiftwidth = 4 -- Number of spaces inserted when indenting
