--- Lua
if vim.fn.executable("lua-language-server") == 1 then
	vim.lsp.config("lua_ls", {
		on_init = function(client)
			if client.workspace_folders then
				local path = client.workspace_folders[1].name
				local is_nvim_config = path:find("nvim", 1, true) ~= nil
				local has_luarc = vim.uv.fs_stat(path .. "/.luarc.json") or vim.uv.fs_stat(path .. "/.luarc.jsonc")

				if not is_nvim_config and has_luarc then
					return
				end
			end

			client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
				runtime = {
					version = "LuaJIT",
					path = {
						"lua/?.lua",
						"lua/?/init.lua",
					},
				},

				workspace = {
					checkThirdParty = false,
					library = {
						vim.env.VIMRUNTIME,
						-- For LSP Settings Type Annotations: https://github.com/neovim/nvim-lspconfig#lsp-settings-type-annotations
						vim.api.nvim_get_runtime_file("lua/lspconfig", false)[1],
					},
				},
			})
		end,
		settings = {
			Lua = {},
		},
	})

	vim.lsp.enable("lua_ls")
end
