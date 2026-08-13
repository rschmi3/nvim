vim.keymap.set("n", "<leader>k", function()
	vim.diagnostic.jump({ count = -1, float = true })
end, { desc = "Previous diagnostic" })

vim.keymap.set("n", "<leader>j", function()
	vim.diagnostic.jump({ count = 1, float = true })
end, { desc = "Next diagnostic" })

vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, { desc = "Diagnostic float" })

vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local opts = { buffer = args.buf }

		vim.keymap.set(
			"n",
			"grd",
			vim.lsp.buf.definition,
			vim.tbl_extend("force", opts, {
				desc = "LSP definition",
			})
		)

		vim.keymap.set(
			"n",
			"grt",
			vim.lsp.buf.type_definition,
			vim.tbl_extend("force", opts, {
				desc = "LSP type definition",
			})
		)
	end,
})
