local hlAugroup = vim.api.nvim_create_augroup("highlight_yank", { clear = true })

vim.api.nvim_create_autocmd("TextYankPost", {
	group = hlAugroup,
	callback = function()
		vim.hl.hl_op({ higroup = "Visual" })
	end,
})

local termAugroup = vim.api.nvim_create_augroup("custom_term_open", { clear = true })

vim.api.nvim_create_autocmd("TermOpen", {
	group = termAugroup,
	pattern = "term://^{*lazygit*}",
	callback = function(args)
		vim.wo.number = false
		vim.wo.relativenumber = false
		vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { buf = args.buf, desc = "Exit terminal mode" })
	end,
	desc = "Disable line numbers in lazygit and close on double esc",
})
