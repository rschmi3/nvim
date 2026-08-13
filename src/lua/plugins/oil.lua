require("oil").setup({
	keymaps = {
		["<C-e>"] = { "actions.close" },
		["<C-h>"] = false,
		["<C-s>"] = { "actions.select_split" },
		["<C-v>"] = { "actions.select_vsplit" },
	},
	view_options = {
		show_hidden = true,
	},
})

vim.keymap.set("n", "<C-e>", "<cmd>Oil<CR>", { desc = "Toggle Oil" })
