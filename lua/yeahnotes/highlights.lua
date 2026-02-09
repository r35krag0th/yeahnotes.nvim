-- Module for custom syntax highlighting (date tags, due dates, etc.)
local M = {}

-- Namespace for extmarks
local ns_id = vim.api.nvim_create_namespace("yeahnotes_highlights")

---Parse a date string in MM/DD/YYYY format
---@param date_str string Date string like "11/10/2025"
---@return number|nil Timestamp or nil if invalid
function M.parse_date(date_str)
	local month, day, year = date_str:match("^(%d+)/(%d+)/(%d+)$")
	if not month or not day or not year then
		return nil
	end

	month = tonumber(month)
	day = tonumber(day)
	year = tonumber(year)

	if not month or not day or not year then
		return nil
	end

	-- Basic validation
	if month < 1 or month > 12 or day < 1 or day > 31 or year < 1900 then
		return nil
	end

	-- Create timestamp
	return os.time({
		year = year,
		month = month,
		day = day,
		hour = 0,
		min = 0,
		sec = 0,
	})
end

---Get today's date at midnight for comparison
---@return number Timestamp of today at midnight
local function get_today_midnight()
	local now = os.date("*t")
	return os.time({
		year = now.year,
		month = now.month,
		day = now.day,
		hour = 0,
		min = 0,
		sec = 0,
	})
end

---Determine the status of a due date
---@param date_timestamp number Timestamp of the due date
---@return string Status: "overdue", "today", or "upcoming"
function M.get_due_date_status(date_timestamp)
	local today = get_today_midnight()

	if date_timestamp < today then
		return "overdue"
	elseif date_timestamp == today then
		return "today"
	else
		return "upcoming"
	end
end

---Define highlight groups
function M.setup_highlight_groups()
	-- Check if terminal supports true colors
	local has_termguicolors = vim.o.termguicolors

	-- Due date highlights (stoplight colors)
	if has_termguicolors then
		vim.api.nvim_set_hl(0, "YeahNotesDueDateOverdue", {
			fg = "#ff6b6b",
			bg = "#3d1f1f",
			bold = true,
			default = false,
		})
		vim.api.nvim_set_hl(0, "YeahNotesDueDateToday", {
			fg = "#ffd93d",
			bg = "#3d3519",
			bold = true,
			default = false,
		})
		vim.api.nvim_set_hl(0, "YeahNotesDueDateUpcoming", {
			fg = "#6bcf7f",
			bg = "#1f3d24",
			bold = true,
			default = false,
		})
		vim.api.nvim_set_hl(0, "YeahNotesDateTag", {
			fg = "#89b4fa",
			bg = "#1e2030",
			bold = true,
			default = false,
		})
	else
		-- Fallback to cterm colors
		vim.api.nvim_set_hl(0, "YeahNotesDueDateOverdue", {
			ctermfg = 203, -- Red
			ctermbg = 52, -- Dark red
			bold = true,
			default = false,
		})
		vim.api.nvim_set_hl(0, "YeahNotesDueDateToday", {
			ctermfg = 221, -- Yellow
			ctermbg = 58, -- Dark yellow
			bold = true,
			default = false,
		})
		vim.api.nvim_set_hl(0, "YeahNotesDueDateUpcoming", {
			ctermfg = 114, -- Green
			ctermbg = 22, -- Dark green
			bold = true,
			default = false,
		})
		vim.api.nvim_set_hl(0, "YeahNotesDateTag", {
			ctermfg = 111, -- Blue
			ctermbg = 235, -- Dark gray
			bold = true,
			default = false,
		})
	end
end

---Apply highlights to a buffer
---@param bufnr integer Buffer number
function M.highlight_buffer(bufnr)
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return
	end

	-- Clear existing highlights first (mini.nvim pattern)
	vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

	for line_num, line in ipairs(lines) do
		-- Check if this is a task line with a due date
		local task_match = line:match("^%s*[%-%*%+]%s*%[[ xX><]%]%s*@(%d+/%d+/%d+)")

		if task_match then
			-- This is a due date on a task
			local date_timestamp = M.parse_date(task_match)
			if date_timestamp then
				local status = M.get_due_date_status(date_timestamp)
				local hl_group = "YeahNotesDueDateOverdue"
				local icon = "⚠"

				if status == "today" then
					hl_group = "YeahNotesDueDateToday"
					icon = "📅"
				elseif status == "upcoming" then
					hl_group = "YeahNotesDueDateUpcoming"
					icon = "📌"
				end

				-- Find the position of the date in the line (including @)
				local date_start_pos, date_end_pos = line:find("@" .. task_match, 1, true)
				if date_start_pos then
					vim.api.nvim_buf_set_extmark(bufnr, ns_id, line_num - 1, date_start_pos - 1, {
						end_col = date_end_pos,
						hl_group = hl_group,
						virt_text = { { icon .. " ", hl_group } },
						virt_text_pos = "inline",
						priority = 5000, -- Higher than Markview's default (4096)
					})
				end
			end
		else
			-- Look for regular date tags (not on tasks)
			local offset = 0
			while true do
				local date_start, date_end, date_str = line:find("@(%d+/%d+/%d+)", offset + 1)
				if not date_start then
					break
				end

				-- Verify it's a valid date
				if M.parse_date(date_str) then
					vim.api.nvim_buf_set_extmark(bufnr, ns_id, line_num - 1, date_start - 1, {
						end_col = date_end,
						hl_group = "YeahNotesDateTag",
						virt_text = { { "📆 ", "YeahNotesDateTag" } },
						virt_text_pos = "inline",
						priority = 5000, -- Higher than Markview's default (4096)
					})
				end

				offset = date_end
			end
		end
	end
end

---Set up autocommands for automatic highlighting
function M.setup_autocommands()
	local augroup = vim.api.nvim_create_augroup("YeahNotesHighlights", { clear = true })

	-- Re-define highlight groups when colorscheme changes
	vim.api.nvim_create_autocmd("ColorScheme", {
		group = augroup,
		callback = function()
			M.setup_highlight_groups()
		end,
		desc = "Re-apply YeahNotes highlight groups after colorscheme change",
	})

	-- Apply highlights when buffer is first displayed or saved
	vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
		group = augroup,
		pattern = "*.md",
		callback = function(args)
			M.highlight_buffer(args.buf)
		end,
		desc = "Highlight YeahNotes date tags on buffer read/write",
	})

	-- Update highlights when leaving insert mode
	vim.api.nvim_create_autocmd("InsertLeave", {
		group = augroup,
		pattern = "*.md",
		callback = function(args)
			M.highlight_buffer(args.buf)
		end,
		desc = "Highlight YeahNotes date tags after leaving insert mode",
	})

	-- Re-highlight when opening notes (for FileType detection)
	vim.api.nvim_create_autocmd("FileType", {
		group = augroup,
		pattern = "markdown",
		callback = function(args)
			M.highlight_buffer(args.buf)
		end,
		desc = "Highlight YeahNotes date tags on markdown filetype",
	})
end

---Initialize the highlights module
function M.setup()
	M.setup_highlight_groups()
	M.setup_autocommands()

	-- Immediately highlight any already-open markdown buffers
	vim.schedule(function()
		for _, buf in ipairs(vim.api.nvim_list_bufs()) do
			if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) then
				local filetype = vim.bo[buf].filetype
				local bufname = vim.api.nvim_buf_get_name(buf)
				if filetype == "markdown" or bufname:match("%.md$") then
					M.highlight_buffer(buf)
				end
			end
		end
	end)
end

return M
