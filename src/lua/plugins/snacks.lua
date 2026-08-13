local Snacks = require("snacks")

local terminal_defs = {
	{ name = "Scratch-1", key = "<A-r>" },
	{ name = "Scratch-2", key = "<A-t>" },
}

Snacks.setup({
	input = { enabled = true },
	picker = { enabled = true },
	terminal = { enabled = true },
})

local terminal_opts = {
	win = {
		border = "rounded",
		height = 0.9,
		position = "float",
		width = 0.9,
	},
}

local terminals = {}
local visible_terminal
local return_win

local function terminal_opts_for(name)
	return vim.tbl_deep_extend("force", {}, terminal_opts, {
		env = { NVIM_TERMINAL_NAME = name },
		win = { title = string.format(" %s ", name) },
	})
end

local function is_terminal_buffer(buf)
	return vim.b[buf].snacks_terminal ~= nil
end

local function remember_return_window()
	local win = vim.api.nvim_get_current_win()
	local buf = vim.api.nvim_win_get_buf(win)
	if not is_terminal_buffer(buf) then
		return_win = win
	end
end

local function hide_terminal(name)
	local terminal = terminals[name]
	if terminal and terminal:valid() then
		terminal:hide()
	end
	if visible_terminal == name then
		visible_terminal = nil
	end
end

local function restore_return_window()
	if return_win and vim.api.nvim_win_is_valid(return_win) then
		vim.api.nvim_set_current_win(return_win)
	end
	return_win = nil
end

local function toggle_terminal(name)
	local terminal = terminals[name]

	if visible_terminal and (not terminals[visible_terminal] or not terminals[visible_terminal]:valid()) then
		visible_terminal = nil
	end

	if visible_terminal == name and terminal and terminal:valid() then
		hide_terminal(name)
		restore_return_window()
		return
	end

	remember_return_window()
	if visible_terminal then
		hide_terminal(visible_terminal)
	end

	if terminal and terminal:buf_valid() then
		terminal:show()
	else
		terminal = Snacks.terminal.get(vim.o.shell, terminal_opts_for(name))
	end
	terminals[name] = terminal
	terminal:focus()
	visible_terminal = name
end

for _, terminal in ipairs(terminal_defs) do
	vim.keymap.set({ "i", "n", "t", "v" }, terminal.key, function()
		toggle_terminal(terminal.name)
	end, { desc = string.format("Toggle %s terminal", terminal.name) })
end
