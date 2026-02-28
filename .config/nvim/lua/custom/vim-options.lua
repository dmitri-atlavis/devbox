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

-- File System
map('n', '-', '<CMD>Oil --float<CR>', { desc = 'Open directory' })

-- Buffer Management: Auto-save and limit to 5 buffers
local function auto_save_buffer()
  if vim.bo.modified and vim.bo.buftype == '' and vim.fn.expand '%' ~= '' then
    vim.cmd 'silent! write'
  end
end

local function manage_buffers()
  local buffers = {}
  local current_buf = vim.api.nvim_get_current_buf()

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted and vim.bo[buf].buftype == '' then
      local bufinfo = vim.fn.getbufinfo(buf)[1]
      if bufinfo and bufinfo.name ~= '' then
        table.insert(buffers, {
          id = buf,
          lastused = bufinfo.lastused,
          name = bufinfo.name,
        })
      end
    end
  end

  -- Sort by last used time (most recent first)
  table.sort(buffers, function(a, b)
    return a.lastused > b.lastused
  end)

  -- If we have more than 5 buffers, close the oldest ones (but not the current buffer)
  if #buffers > 5 then
    local to_close = {}
    for i = 6, #buffers do
      local buf_id = buffers[i].id
      if buf_id ~= current_buf then
        table.insert(to_close, buf_id)
      end
    end

    for _, buf_id in ipairs(to_close) do
      -- Auto-save before closing
      if vim.api.nvim_buf_is_valid(buf_id) and vim.bo[buf_id].modified then
        pcall(function()
          vim.api.nvim_buf_call(buf_id, function()
            vim.cmd 'silent! write'
          end)
        end)
      end
      -- Close the buffer safely
      pcall(vim.api.nvim_buf_delete, buf_id, { force = false })
    end
  end
end

-- Auto-save on buffer leave and manage buffer count on buffer enter
local buffer_group = vim.api.nvim_create_augroup('BufferManagement', { clear = true })
vim.api.nvim_create_autocmd('BufLeave', {
  group = buffer_group,
  callback = auto_save_buffer,
  desc = 'Auto-save buffer on leave',
})
vim.api.nvim_create_autocmd('BufEnter', {
  group = buffer_group,
  callback = manage_buffers,
  desc = 'Manage buffer count limit',
})

