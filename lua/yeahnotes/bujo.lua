local navigation = require("yeahnotes.navigation")
local config = require("yeahnotes.config")
local template = require("yeahnotes.template")

local M = {}

--- Parse tasks from buffer lines
--- Supports formats: - [ ] task, * [ ] task, + [ ] task
---@param lines string[] Lines to parse
---@return table[] Array of {line_num: number, text: string, completed: boolean}
function M.parse_tasks(lines)
	local tasks = {}

	for i, line in ipairs(lines) do
		-- Match common checkbox formats: - [ ], * [ ], + [ ]
		-- Also match: - [x], - [X], - [>] for completed/migrated
		local prefix, checkbox, task_text = line:match("^(%s*[%-%*%+])%s*(%[[ xX>]%])%s*(.+)$")

		if prefix and checkbox and task_text then
			local completed = checkbox:match("%[[ ]%]") == nil -- If not empty checkbox, it's completed
			table.insert(tasks, {
				line_num = i,
				text = task_text,
				completed = completed,
				original_line = line,
				prefix = prefix,
				checkbox = checkbox,
			})
		end
	end

	return tasks
end

--- Get incomplete tasks from the current buffer
---@return table[] Array of incomplete tasks
function M.get_incomplete_tasks()
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local all_tasks = M.parse_tasks(lines)

	-- Filter to only incomplete tasks
	local incomplete = {}
	for _, task in ipairs(all_tasks) do
		if not task.completed then
			table.insert(incomplete, task)
		end
	end

	return incomplete
end

--- Mark a task as migrated in the current buffer
---@param line_num number The line number to mark (1-indexed)
function M.mark_as_migrated(line_num)
	local line = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1]

	if not line then
		return
	end

	-- Replace [ ] with [>] to indicate migration
	local updated = line:gsub("%[[ ]%]", "[>]", 1)

	if updated ~= line then
		vim.api.nvim_buf_set_lines(0, line_num - 1, line_num, false, { updated })
	end
end

--- Toggle a single line's checkbox between done and not done
--- [ ] → [x], [x]/[X] → [ ], [>] → [x]
---@param line string The line content
---@return string|nil The updated line, or nil if no checkbox found
local function toggle_line(line)
	if line:match("%[[ ]%]") then
		return line:gsub("%[[ ]%]", "[x]", 1)
	elseif line:match("%[[xX]%]") then
		return line:gsub("%[[xX]%]", "[ ]", 1)
	elseif line:match("%[>%]") then
		return line:gsub("%[>%]", "[x]", 1)
	end
	return nil
end

--- Toggle checkboxes between done and not done
--- Works from anywhere on the line. Supports single line (normal mode)
--- and visual line selection.
---@param range? {start_line: number, end_line: number} Optional 1-indexed line range
function M.toggle_checkbox(range)
	local start_line, end_line

	if range then
		start_line = range.start_line
		end_line = range.end_line
	else
		local cursor = vim.api.nvim_win_get_cursor(0)
		start_line = cursor[1]
		end_line = cursor[1]
	end

	local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)

	for i, line in ipairs(lines) do
		local updated = toggle_line(line)
		if updated then
			lines[i] = updated
		end
	end

	vim.api.nvim_buf_set_lines(0, start_line - 1, end_line, false, lines)
end

--- Append tasks to a file, creating sections if needed
---@param file_path string Path to the target file
---@param tasks table[] Array of tasks to append
---@param section_title? string Optional section title (default: "## Migrated Tasks")
function M.append_tasks_to_file(file_path, tasks, section_title)
	if #tasks == 0 then
		return
	end

	section_title = section_title or "## Migrated Tasks"

	-- Read existing content
	local file = io.open(file_path, "r")
	local existing_content = ""
	if file then
		existing_content = file:read("*all")
		file:close()
	end

	-- Prepare new content
	local new_lines = {}

	-- Add blank line if file isn't empty and doesn't end with newline
	if existing_content ~= "" and not existing_content:match("\n$") then
		table.insert(new_lines, "")
	end

	-- Add section header if content exists, otherwise start fresh
	if existing_content ~= "" then
		table.insert(new_lines, "")
		table.insert(new_lines, section_title)
	end

	-- Add tasks
	for _, task in ipairs(tasks) do
		table.insert(new_lines, "- [ ] " .. task.text)
	end

	-- Write to file
	file = io.open(file_path, "a")
	if file then
		file:write(table.concat(new_lines, "\n") .. "\n")
		file:close()
	else
		vim.notify("Failed to write to " .. file_path, vim.log.levels.ERROR)
	end
end

--- Get the file path and date for tomorrow's journal
---@return string, osdate File path and date for tomorrow's journal
function M.get_tomorrow_path()
	local tomorrow = os.time() + 86400 -- Add one day

	-- Skip weekends
	local wday = tonumber(os.date("%w", tomorrow))
	while wday == 0 or wday == 6 do
		tomorrow = tomorrow + 86400
		wday = tonumber(os.date("%w", tomorrow))
	end

	local year = os.date("%Y", tomorrow)
	local month = os.date("%m", tomorrow)
	local day = os.date("%d", tomorrow)

	local journal_path = string.format("%s/journal/%s/%s", config.options.root, year, month)
	vim.fn.mkdir(journal_path, "p")

	return string.format("%s/%s.md", journal_path, day), tomorrow
end

--- Migrate incomplete tasks from current buffer to tomorrow
---@param opts? {mark_migrated: boolean, open_tomorrow: boolean} Options
function M.migrate_to_tomorrow(opts)
	opts = opts or {}
	opts.mark_migrated = opts.mark_migrated ~= false -- Default true
	opts.open_tomorrow = opts.open_tomorrow or false

	-- Check if we're in a journal file
	local current = navigation.current_file()
	if not current then
		vim.notify("Not currently in a journal file", vim.log.levels.WARN)
		return
	end

	-- Get incomplete tasks
	local incomplete_tasks = M.get_incomplete_tasks()

	if #incomplete_tasks == 0 then
		vim.notify("No incomplete tasks to migrate", vim.log.levels.INFO)
		return
	end

	-- Get tomorrow's file path and date
	local tomorrow_path, tomorrow_date = M.get_tomorrow_path()

	-- Save current buffer before modifying
	vim.cmd("write")

	-- Apply template if tomorrow's file is new/empty
	template.apply_if_new(tomorrow_path, tomorrow_date)

	-- Append tasks to tomorrow
	M.append_tasks_to_file(tomorrow_path, incomplete_tasks, "## Migrated from " .. os.date("%Y-%m-%d"))

	-- Mark tasks as migrated in current buffer
	if opts.mark_migrated then
		for _, task in ipairs(incomplete_tasks) do
			M.mark_as_migrated(task.line_num)
		end
	end

	vim.notify(
		string.format("Migrated %d task%s to tomorrow", #incomplete_tasks, #incomplete_tasks == 1 and "" or "s"),
		vim.log.levels.INFO
	)

	-- Optionally open tomorrow's file
	if opts.open_tomorrow then
		vim.cmd("edit " .. tomorrow_path)
	end
end

return M
