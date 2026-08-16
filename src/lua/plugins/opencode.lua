local opencode_cmd = "opencode --port"
local Snacks = require("snacks")
local state = {
	starting_local = false,
	local_owned = false,
	local_url = nil,
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
	auto_reload = true,
	events = {
		reload = {
			enabled = true,
		},
	},
	lsp = {
		enabled = false,
		handlers = {
			hover = { enabled = false },
			code_action = { enabled = false },
		},
	},
	server = {
		start = function()
			state.starting_local = true
			state.local_owned = true
			Snacks.terminal.open(opencode_cmd, terminal_opts)
		end,
	},
}

local function connected_server()
	return require("opencode.server").connected
end

local function local_terminal()
	return Snacks.terminal.get(opencode_cmd, { create = false })
end

local function using_local_server()
	local server = connected_server()
	return state.local_owned and server and state.local_url and server.url == state.local_url
end

local function start_local_terminal()
	state.starting_local = true
	state.local_owned = true
	Snacks.terminal.open(opencode_cmd, terminal_opts)
end

vim.keymap.set({ "n", "x" }, "<leader>oa", function()
	require("opencode").ask("@this: ")
end, { desc = "Ask Opencode and submit" })

vim.keymap.set("n", "<leader>ov", function()
	state.starting_local = false
	state.local_owned = false
	state.local_url = nil
	require("opencode").select()
end, { desc = "Opencode select" })

vim.keymap.set("n", "<leader>ot", function()
	if using_local_server() then
		Snacks.terminal.toggle(opencode_cmd, terminal_opts)
		return
	end

	if not connected_server() then
		start_local_terminal()
		return
	end

	vim.notify("Connected to a remote Opencode server; terminal toggle is local-only", vim.log.levels.INFO, {
		title = "opencode",
	})
end, { desc = "Opencode toggle" })

vim.keymap.set("n", "<leader>oc", function()
	local server = connected_server()
	if not server then
		if state.local_owned then
			local terminal = local_terminal()
			if terminal then
				terminal:close()
			end
			state.starting_local = false
			state.local_owned = false
			state.local_url = nil
		else
			vim.notify("No managed local Opencode instance is running", vim.log.levels.INFO, { title = "opencode" })
		end
		return
	end

	local is_local = using_local_server()
	server:disconnect()

	if is_local then
		local terminal = local_terminal()
		if terminal then
			terminal:close()
		end
		state.starting_local = false
		state.local_owned = false
		state.local_url = nil
		return
	end

	vim.notify("Disconnected from remote Opencode server", vim.log.levels.INFO, { title = "opencode" })
end, { desc = "Opencode stop" })

vim.keymap.set({ "n", "x" }, "go", function()
	return require("opencode").operator("@this ")
end, { desc = "Add range to Opencode", expr = true })

vim.keymap.set("n", "goo", function()
	return require("opencode").operator("@this ") .. "_"
end, { desc = "Add line to Opencode", expr = true })

vim.keymap.set("n", "<S-C-u>", function()
	require("opencode").command("session.half.page.up")
end, { desc = "Scroll Opencode up" })

vim.keymap.set("n", "<S-C-d>", function()
	require("opencode").command("session.half.page.down")
end, { desc = "Scroll Opencode down" })

vim.keymap.set("t", "<C-w>h", "<C-\\><C-n><C-w>h", { desc = "Exit terminal and move left" })

vim.api.nvim_create_autocmd("User", {
	pattern = "OpencodeEvent:*",
	callback = function(args)
		local event = args.data and args.data.event
		local url = args.data and args.data.url

		if event and event.type == "server.connected" then
			if state.starting_local and url then
				state.local_url = url
				state.local_owned = true
			else
				state.local_url = nil
				state.local_owned = false
			end
			state.starting_local = false
		elseif event and event.type == "server.instance.disposed" then
			state.starting_local = false
			state.local_owned = false
			state.local_url = nil
		end

		if event and event.properties and event.properties.command == "prompt.submit" then
			local terminal = local_terminal()
			if terminal then
				terminal:show()
			end
		end
	end,
})
