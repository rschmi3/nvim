local augroup = vim.api.nvim_create_augroup("treesitter", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
	group = augroup,
	pattern = "*",
	callback = function(args)
		local max_filesize = 100 * 1024
		local filename = vim.api.nvim_buf_get_name(args.buf)
		local ok, stats = pcall(vim.uv.fs_stat, filename)

		if ok and stats and stats.size > max_filesize then
			return
		end

		local filetype = vim.bo[args.buf].filetype
		local lang = vim.treesitter.language.get_lang(filetype) or filetype

		pcall(vim.treesitter.start, args.buf, lang)

		vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()" -- folds
		vim.wo.foldmethod = "expr"
		vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()" -- indentation
	end,
})
