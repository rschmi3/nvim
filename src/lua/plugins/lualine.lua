local function opencode_status()
	local ok, opencode = pcall(require, "opencode")
	if not ok or type(opencode.statusline) ~= "function" then
		return ""
	end

	return opencode.statusline()
end

require("lualine").setup({
	sections = {
		lualine_z = {
			opencode_status,
		},
	},
})
