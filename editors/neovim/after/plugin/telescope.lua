local tb = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', tb.find_files, {})
vim.keymap.set('n', '<leader>fg', ":lua require('telescope').extensions.live_grep_args.live_grep_args()<CR>")
vim.keymap.set('n', '<leader>fb', tb.buffers, {})
vim.keymap.set('n', '<leader>fh', tb.help_tags, {})
vim.keymap.set('n', '<leader>fs', tb.lsp_document_symbols, {})
vim.keymap.set('n', '<leader>fo', tb.oldfiles, {})
vim.keymap.set('n', '<leader>fw', tb.grep_string, {})
vim.keymap.set('n', '<leader>fp', tb.builtin, {})  -- list the telescope builtin pickers. To not clutter mappings, but still be able to access many less used pickers

local telescope = require("telescope")
local ta = require("telescope.actions")
telescope.setup({
    defaults = {
        mappings = {
            i = {
                ["<C-j>"] = ta.cycle_history_next,
                ["<C-k>"] = ta.cycle_history_prev,
            }
        }
    }
})

telescope.load_extension("live_grep_args")
