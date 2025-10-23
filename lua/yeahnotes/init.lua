local config = require("yeahnotes.config")
local commands = require("yeahnotes.commands")
local pickers = require("yeahnotes.pickers")

local M = {}

--- Setup the plugin with user options
---@param opts? yeahnotes.Config
function M.setup(opts)
	config.setup(opts)

	-- Create the root notes directory if it doesn't exist
	vim.fn.mkdir(config.options.root, "p")

	-- Set up keymaps if they're configured
	if config.options.keymap then
		local keymap = vim.keymap.set
		local km = config.options.keymap

		if km.today then
			keymap("n", km.today, commands.today, { desc = "YeahNotes: Today" })
		end
		if km.yesterday then
			keymap("n", km.yesterday, commands.yesterday, { desc = "YeahNotes: Yesterday" })
		end
		if km.tomorrow then
			keymap("n", km.tomorrow, commands.tomorrow, { desc = "YeahNotes: Tomorrow" })
		end
		if km.previous_no_skip then
			keymap("n", km.previous_no_skip, commands.previous, { desc = "YeahNotes: Previous day" })
		end
		if km.previous_with_skip then
			keymap("n", km.previous_with_skip, commands.previous_skip_empty, { desc = "YeahNotes: Previous (skip empty)" })
		end
		if km.next_no_skip then
			keymap("n", km.next_no_skip, commands.next, { desc = "YeahNotes: Next day" })
		end
		if km.next_with_skip then
			keymap("n", km.next_with_skip, commands.next_skip_empty, { desc = "YeahNotes: Next (skip empty)" })
		end
		if km.find then
			keymap("n", km.find, pickers.find_files, { desc = "YeahNotes: Find files" })
		end
		if km.grep then
			keymap("n", km.grep, pickers.grep, { desc = "YeahNotes: Grep notes" })
		end
		if km.migrate then
			keymap("n", km.migrate, commands.migrate_to_tomorrow, { desc = "YeahNotes: Migrate tasks to tomorrow" })
		end
		if km.migrate_and_open then
			keymap("n", km.migrate_and_open, commands.migrate_and_open, { desc = "YeahNotes: Migrate and open tomorrow" })
		end
	end
end

-- Export commands and pickers for use in user commands
M.commands = commands
M.pickers = pickers

return M
