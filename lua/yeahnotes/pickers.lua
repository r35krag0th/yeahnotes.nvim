local config = require("yeahnotes.config")

local M = {}

--- Find files in the notes directory using mini.pick
function M.find_files()
	local ok, pick = pcall(require, "mini.pick")
	if not ok then
		vim.notify("mini.pick is not available", vim.log.levels.ERROR)
		return
	end

	pick.builtin.files({}, { source = { cwd = config.options.root } })
end

--- Grep through notes using mini.pick
function M.grep()
	local ok, pick = pcall(require, "mini.pick")
	if not ok then
		vim.notify("mini.pick is not available", vim.log.levels.ERROR)
		return
	end

	pick.builtin.grep_live({}, { source = { cwd = config.options.root } })
end

return M
