local function fail(message)
	error("opencode integration test failed: " .. message, 0)
end

local original_notify = vim.notify

local function wait_for(predicate, message)
	if not vim.wait(3000, predicate, 10) then
		fail(message)
	end
end

local function assert_equal(actual, expected, message)
	if actual ~= expected then
		fail(string.format("%s (expected %s, got %s)", message, vim.inspect(expected), vim.inspect(actual)))
	end
end

local function mapping(lhs)
	local target = vim.g.mapleader .. lhs
	for _, map in ipairs(vim.api.nvim_get_keymap("n")) do
		if map.lhs == target and type(map.callback) == "function" then
			return map.callback
		end
	end
	fail("missing normal-mode mapping " .. lhs)
end

local function press(lhs)
	mapping(lhs)
	local keys = vim.api.nvim_replace_termcodes(vim.g.mapleader .. lhs, true, false, true)
	vim.api.nvim_feedkeys(keys, "mx", false)
end

local function process_count(log)
	if vim.fn.filereadable(log) == 0 then
		return 0
	end
	return #vim.fn.readfile(log)
end

local function terminal_visible(terminal)
	return terminal and terminal.win and vim.api.nvim_win_is_valid(terminal.win)
end

local function run()
	local log = vim.env.OPENCODE_TEST_LOG
	assert(log and log ~= "", "OPENCODE_TEST_LOG must be set")

	local opencode = require("opencode")
	local server_module = require("opencode.server")
	local config = require("opencode.config").opts
	local Snacks = require("snacks")

	assert(type(opencode.statusline) == "function", "OpenCode statusline API is missing")
	assert(type(opencode.statusline()) == "string", "OpenCode statusline did not return a string")
	assert(config.events.reload.enabled, "OpenCode buffer reload integration is disabled")
	assert(type(config.server.start) == "function", "custom Snacks server startup is missing")
	local blink = require("blink.cmp")
	assert(blink, "Blink is unavailable")
	assert(require("lualine"), "Lualine is unavailable")
	local blink_config = require("blink.cmp.config")
	local ask_sources = blink_config.sources.per_filetype.opencode_ask or blink_config.sources.default
	assert(vim.tbl_contains(ask_sources, "lsp"), "Blink LSP source is not enabled for OpenCode Ask")

	local ask_on_buf = config.ask.snacks.win.on_buf
	assert(type(ask_on_buf) == "function", "OpenCode Ask does not start its in-process completion LSP")
	local ask_buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(ask_buf, 0, -1, false, { "@" })
	ask_on_buf({ buf = ask_buf })
	local client
	wait_for(function()
		for _, candidate in ipairs(vim.lsp.get_clients({ bufnr = ask_buf })) do
			if candidate.name == "opencode_ask_cmp" then
				client = candidate
				return true
			end
		end
		return false
	end, "OpenCode Ask completion LSP did not start")
	local completion_result
	client:request(vim.lsp.protocol.Methods.textDocument_completion, {
		textDocument = { uri = vim.uri_from_bufnr(ask_buf) },
		position = { line = 0, character = 1 },
	}, function(err, result)
		assert(not err, "OpenCode Ask completion request failed: " .. vim.inspect(err))
		completion_result = result
	end, ask_buf)
	wait_for(function()
		return completion_result ~= nil
	end, "OpenCode Ask completion request timed out")
	assert(
		vim.tbl_contains(
			vim.tbl_map(function(item)
				return item.label
			end, completion_result),
			"@this"
		),
		"OpenCode Ask completion did not offer @this"
	)
	vim.api.nvim_buf_delete(ask_buf, { force = true })

	vim.notify = function() end
	local remote = {
		url = "http://127.0.0.1:9876",
		disconnect = function(self)
			self.disconnected = true
			server_module.connected = nil
		end,
	}
	server_module.connected = remote
	press("ot")
	assert_equal(process_count(log), 0, "remote toggle launched a local OpenCode terminal")
	press("oc")
	assert(remote.disconnected, "stop mapping did not disconnect the remote server")
	assert_equal(process_count(log), 0, "remote stop launched a local OpenCode terminal")
	vim.notify = original_notify

	server_module.connected = nil
	press("ot")
	wait_for(function()
		return process_count(log) == 1
	end, "local toggle did not launch the fake OpenCode executable")

	local terminal = Snacks.terminal.get("opencode", { create = false })
	assert(terminal and terminal:buf_valid(), "local Snacks terminal was not created")
	local scroll_mappings = {}
	for _, map in ipairs(vim.api.nvim_buf_get_keymap(terminal.buf, "t")) do
		if map.desc == "Scroll OpenCode up" or map.desc == "Scroll OpenCode down" then
			scroll_mappings[map.desc] = map.rhs
		end
	end
	assert_equal(scroll_mappings["Scroll OpenCode up"], "<PageUp>", "Ctrl+Alt+U is not mapped to PageUp")
	assert_equal(scroll_mappings["Scroll OpenCode down"], "<PageDown>", "Ctrl+Alt+D is not mapped to PageDown")
	wait_for(function()
		return terminal_visible(terminal)
	end, "local terminal did not become visible")

	press("ot")
	assert(not terminal_visible(terminal), "second toggle did not hide the existing terminal")
	press("ot")
	assert(terminal_visible(terminal), "third toggle did not show the existing terminal")
	assert_equal(process_count(log), 1, "repeated toggles launched duplicate OpenCode processes")

	config.server.start()
	assert(terminal_visible(terminal), "server.start did not show the existing local terminal")
	assert_equal(process_count(log), 1, "server.start launched a duplicate terminal")

	terminal:hide()
	require("opencode.events").emit({
		type = "session.execution.started",
		data = {},
	}, { url = "http://127.0.0.1:4096" })
	assert(terminal_visible(terminal), "execution-started event did not show the local terminal")

	press("oc")
	wait_for(function()
		return not terminal:buf_valid()
	end, "stop mapping did not close the managed terminal")

	assert_equal(process_count(log), 1, "stopping the local terminal unexpectedly relaunched OpenCode")
	print("opencode integration checks passed")
end

local ok, err = xpcall(run, debug.traceback)

local snacks_ok, Snacks = pcall(require, "snacks")
if snacks_ok then
	local terminal = Snacks.terminal.get("opencode", { create = false })
	if terminal then
		pcall(function()
			terminal:close()
		end)
	end
end

if not ok then
	vim.notify = original_notify
	io.stderr:write(err .. "\n")
	vim.cmd("cquit 1")
else
	vim.notify = original_notify
	vim.cmd("qa!")
end
