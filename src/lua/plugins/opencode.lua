local opencode_cmd = "opencode"
local Snacks = require("snacks")
local state = {
	local_owned = false,
}

local terminal_opts = {
	interactive = true,
	auto_close = false,
	win = {
		position = "right",
		enter = false,
	},
}

vim.g.opencode_opts = {
	events = {
		reload = {
			enabled = true,
		},
	},
	server = {
		start = function()
			state.local_owned = true
			local terminal = Snacks.terminal.get(
				opencode_cmd,
				vim.tbl_extend("force", {}, terminal_opts, {
					create = false,
				})
			)
			if terminal and terminal:buf_valid() then
				terminal:show()
			else
				Snacks.terminal.open(opencode_cmd, terminal_opts)
			end
		end,
	},
}

local function connected_server()
	return require("opencode.server").connected
end

local function local_terminal()
	return Snacks.terminal.get(opencode_cmd, vim.tbl_extend("force", {}, terminal_opts, { create = false }))
end

local function start_local_terminal()
	state.local_owned = true
	local terminal = local_terminal()
	if terminal and terminal:buf_valid() then
		terminal:show()
	else
		Snacks.terminal.open(opencode_cmd, terminal_opts)
	end
end

vim.keymap.set({ "n", "x" }, "<leader>oa", function()
	require("opencode").ask("@this: ")
end, { desc = "Ask Opencode and submit" })

vim.keymap.set("n", "<leader>ov", function()
	state.local_owned = false
	require("opencode").select()
end, { desc = "Opencode select" })

vim.keymap.set("n", "<leader>ot", function()
	local server = connected_server()
	if server and not state.local_owned then
		vim.notify("Connected to a remote Opencode server; terminal toggle is local-only", vim.log.levels.INFO, {
			title = "opencode",
		})
		return
	end

	local terminal = local_terminal()
	if terminal and terminal:buf_valid() then
		state.local_owned = true
		if terminal.win and vim.api.nvim_win_is_valid(terminal.win) then
			terminal:hide()
		else
			terminal:show()
		end
		return
	end

	state.local_owned = false
	start_local_terminal()
end, { desc = "Opencode toggle" })

vim.keymap.set("n", "<leader>oc", function()
	local server = connected_server()
	if not server then
		if state.local_owned then
			local terminal = local_terminal()
			if terminal then
				terminal:close()
			end
			state.local_owned = false
		else
			vim.notify("No managed local Opencode instance is running", vim.log.levels.INFO, { title = "opencode" })
		end
		return
	end

	server:disconnect()

	if state.local_owned then
		local terminal = local_terminal()
		if terminal then
			terminal:close()
		end
		state.local_owned = false
		return
	end

	vim.notify("Disconnected from remote Opencode server", vim.log.levels.INFO, { title = "opencode" })
end, { desc = "Opencode stop" })

vim.keymap.set({ "n", "x" }, "go", function()
	return require("opencode").operator("@this...")
end, { desc = "Add range to Opencode", expr = true })

vim.keymap.set("n", "goo", function()
	return require("opencode").operator("@this...") .. "_"
end, { desc = "Add line to Opencode", expr = true })

vim.api.nvim_create_autocmd("TermOpen", {
	callback = function(args)
		local terminal = vim.b[args.buf].snacks_terminal
		if not terminal or terminal.cmd ~= opencode_cmd then
			return
		end

		vim.keymap.set("t", "<C-M-u>", "<PageUp>", {
			buffer = args.buf,
			desc = "Scroll OpenCode up",
		})
		vim.keymap.set("t", "<C-M-d>", "<PageDown>", {
			buffer = args.buf,
			desc = "Scroll OpenCode down",
		})
	end,
})

vim.keymap.set("t", "<C-w>h", "<C-\\><C-n><C-w>h", { desc = "Exit terminal and move left" })

vim.api.nvim_create_autocmd("User", {
	pattern = "OpencodeEvent:session.execution.started",
	callback = function(args)
		local terminal = local_terminal()
		if terminal and terminal:buf_valid() then
			terminal:show()
		end
	end,
})
