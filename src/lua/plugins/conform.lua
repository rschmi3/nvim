local conform = require("conform")

conform.setup({
	default_format_opts = {
		lsp_format = "fallback",
		timeout_ms = 4000,
	},
	formatters = {
		pg_format = {
			prepend_args = { "--no-space-function" },
		},
		prettier = {
			prepend_args = { "--ignore-path", ".prettierignore" },
		},
		ruff_format = {
			command = "ruff",
			args = { "format", "--stdin-filename", "$FILENAME", "-" },
			stdin = true,
		},
	},
	formatters_by_ft = {
		bash = { "beautysh" },
		c = { "clang_format" },
		css = { "prettier" },
		go = { "gofmt" },
		javascript = { "prettier" },
		json = { "prettier" },
		lua = { "stylua" },
		nix = { "nixfmt" },
		python = { "isort", "ruff_format" },
		rust = { "rustfmt" },
		sh = { "beautysh" },
		sql = { "pg_format" },
		toml = { "tombi" },
		typescript = { "prettier" },
	},
	format_on_save = {
		lsp_format = "fallback",
		timeout_ms = 4000,
	},
})

vim.keymap.set("n", "<leader><leader>f", function()
	conform.format({ async = true })
end, { desc = "Format buffer" })
