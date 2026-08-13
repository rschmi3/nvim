vim.keymap.set("n", "<leader><leader>x", function()
	vim.cmd.source("%")
end, { desc = "Source current file" })

vim.keymap.set("n", "<leader>x", "<cmd>.lua<CR>", { desc = "Run Lua line" })
vim.keymap.set("v", "<leader>x", ":lua<CR>", { desc = "Run Lua selection" })

-- Quickfix bindings
vim.keymap.set("n", "<M-j>", "<cmd>cnext<CR>", { desc = "Quickfix next" })
vim.keymap.set("n", "<M-k>", "<cmd>cprev<CR>", { desc = "Quickfix previous" })
vim.keymap.set("n", "<M-c>", "<cmd>cclose<CR>", { desc = "Quickfix close" })
vim.keymap.set("n", "<M-o>", "<cmd>copen<CR>", { desc = "Quickfix open" })
vim.keymap.set("n", "<M-d>", function()
	vim.diagnostic.setqflist({ severity = vim.diagnostic.severity.ERROR })
end, { desc = "Quickfix errors" })

-- Clear highlights on search when pressing <Esc> in normal mode
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlights" })

-- Disable arrow keys in normal mode
vim.keymap.set("n", "<left>", function()
	print("Use h to move!!")
end, { desc = "Left disable" })

vim.keymap.set("n", "<right>", function()
	print("Use l to move!!")
end, { desc = "Right disable" })

vim.keymap.set("n", "<down>", function()
	print("Use j to move!!")
end, { desc = "Down disable" })

vim.keymap.set("n", "<up>", function()
	print("Use k to move!!")
end, { desc = "Up disable" })

-- Center cursor on page up and down
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Page up and centre" })
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Page down and centre" })

-- Copy to and from system clipboard
vim.keymap.set("n", "<leader>y", function()
	vim.fn.setreg("+", vim.fn.getreg('"'))
end, { desc = "Copy from unnamed to system clipboard" })

vim.keymap.set("n", "<leader>p", function()
	vim.fn.setreg('"', vim.fn.getreg("+"))
end, { desc = "Copy from system clipboard to unnamed" })
