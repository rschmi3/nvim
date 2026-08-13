require("lsp.lua_ls")
require("lsp.nixd")
require("lsp.keymaps")

if vim.fn.executable("ccls") == 1 then
	vim.lsp.enable("ccls")
end

if vim.fn.executable("docker-langserver") == 1 then
	vim.lsp.config("docker_language_server", {
		cmd = { "docker-langserver", "start", "--stdio" },
	})
	vim.lsp.enable("docker_language_server")
end

if vim.fn.executable("gopls") == 1 then
	vim.lsp.enable("gopls")
end

if vim.fn.executable("vscode-css-language-server") == 1 then
	vim.lsp.enable("cssls")
end

if vim.fn.executable("vscode-html-language-server") == 1 then
	vim.lsp.enable("html")
end

if vim.fn.executable("htmx-lsp") == 1 then
	vim.lsp.enable("htmx")
end

if vim.fn.executable("pyright-langserver") == 1 then
	vim.lsp.config("pyright", {
		settings = {
			pyright = {
				disableOrganizeImports = true,
			},
		},
	})
	vim.lsp.enable("pyright")
end

if vim.fn.executable("ruff") == 1 then
	vim.lsp.config("ruff", {
		init_options = {
			settings = {
				organizeImports = true,
			},
		},
	})
	vim.lsp.enable("ruff")
end

if vim.fn.executable("rust-analyzer") == 1 then
	vim.lsp.enable("rust_analyzer")
end

if vim.fn.executable("typescript-language-server") == 1 then
	vim.lsp.enable("ts_ls")
end
