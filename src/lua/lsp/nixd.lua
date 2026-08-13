if vim.fn.executable("nixd") == 1 then
	vim.lsp.config("nixd", {
		settings = {
			nixd = {
				nixpkgs = {
					expr = '(builtins.getFlake "github:NixOS/nixpkgs/nixos-unstable").legacyPackages.x86_64-linux',
				},
			},
		},
	})
	vim.lsp.enable("nixd")
end
