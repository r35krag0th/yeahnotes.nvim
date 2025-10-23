local config = require("yeahnotes.config")
local template = require("yeahnotes.template")

local M = {}

--- Opens a journal entry for the given date
---@param date osdate The date to open
function M.date_to_journal(date)
	local year = os.date("%Y", date)
	local month = os.date("%m", date)
	local day = os.date("%d", date)

	local journal_path = string.format("%s/journal/%s/%s", config.options.root, year, month)
	local journal_file = string.format("%s/%s.md", journal_path, day)

	-- Create directory if it doesn't exist
	vim.fn.mkdir(journal_path, "p")

	-- Apply template if this is a new file
	template.apply_if_new(journal_file, date)

	-- Open the file
	vim.cmd("edit " .. journal_file)
end

--- Navigate to a journal entry relative to a starting date, skipping weekends
---@param days number Number of days to move (positive = forward, negative = backward)
---@param start_at? osdate Starting date (defaults to today)
function M.relative_to_journal(days, start_at)
	local date = start_at or os.time()
	local direction = days > 0 and 1 or -1

	-- Move day by day, skipping weekends
	for _ = 1, math.abs(days) do
		date = date + (direction * 86400) -- 86400 seconds = 1 day

		-- Skip weekends (Saturday = 7, Sunday = 1)
		local wday = tonumber(os.date("%w", date))
		while wday == 0 or wday == 6 do
			date = date + (direction * 86400)
			wday = tonumber(os.date("%w", date))
		end
	end

	M.date_to_journal(date)
end

--- Parse the current buffer's filename to extract date information
---@return table|nil { year: number, month: number, day: number, date: osdate } or nil if not a journal file
function M.current_file()
	local bufname = vim.api.nvim_buf_get_name(0)

	-- Extract year, month, day from path like: .../journal/YYYY/MM/DD.md
	local year, month, day = bufname:match("/journal/(%d%d%d%d)/(%d%d)/(%d%d)%.md$")

	if not year or not month or not day then
		return nil
	end

	-- Create a date object for this journal entry
	local date = os.time({
		year = tonumber(year),
		month = tonumber(month),
		day = tonumber(day),
		hour = 0,
		min = 0,
		sec = 0,
	})

	return {
		year = tonumber(year),
		month = tonumber(month),
		day = tonumber(day),
		date = date,
	}
end

--- Navigate to the previous journal entry
---@param skip_empty? boolean Whether to skip empty journal files
function M.goto_previous_day(skip_empty)
	local current = M.current_file()

	if not current then
		vim.notify("Not currently in a journal file", vim.log.levels.ERROR)
		return
	end

	local target_date = current.date

	repeat
		-- Go back one weekday
		target_date = target_date - 86400
		local wday = tonumber(os.date("%w", target_date))
		while wday == 0 or wday == 6 do
			target_date = target_date - 86400
			wday = tonumber(os.date("%w", target_date))
		end

		-- Check if file is empty (if skip_empty is true)
		if skip_empty then
			local year = os.date("%Y", target_date)
			local month = os.date("%m", target_date)
			local day = os.date("%d", target_date)
			local path = string.format("%s/journal/%s/%s/%s.md", config.options.root, year, month, day)

			local file = io.open(path, "r")
			if file then
				local content = file:read("*all")
				file:close()
				if content and #vim.trim(content) > 0 then
					break
				end
			else
				break -- File doesn't exist, treat as non-empty to open it
			end
		else
			break
		end
	until false

	M.date_to_journal(target_date)
end

--- Navigate to the next journal entry
---@param skip_empty? boolean Whether to skip empty journal files
function M.goto_next_day(skip_empty)
	local current = M.current_file()

	if not current then
		vim.notify("Not currently in a journal file", vim.log.levels.ERROR)
		return
	end

	local target_date = current.date

	repeat
		-- Go forward one weekday
		target_date = target_date + 86400
		local wday = tonumber(os.date("%w", target_date))
		while wday == 0 or wday == 6 do
			target_date = target_date + 86400
			wday = tonumber(os.date("%w", target_date))
		end

		-- Check if file is empty (if skip_empty is true)
		if skip_empty then
			local year = os.date("%Y", target_date)
			local month = os.date("%m", target_date)
			local day = os.date("%d", target_date)
			local path = string.format("%s/journal/%s/%s/%s.md", config.options.root, year, month, day)

			local file = io.open(path, "r")
			if file then
				local content = file:read("*all")
				file:close()
				if content and #vim.trim(content) > 0 then
					break
				end
			else
				break -- File doesn't exist, treat as non-empty to open it
			end
		else
			break
		end
	until false

	M.date_to_journal(target_date)
end

return M
