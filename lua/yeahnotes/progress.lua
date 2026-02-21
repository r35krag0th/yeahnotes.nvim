-- Module for task completion progress indicators on parent tasks
local M = {}

local config = require("yeahnotes.config")

-- Separate namespace so progress extmarks don't interfere with date tag highlights
local ns_id = vim.api.nvim_create_namespace("yeahnotes_progress")

-- Re-entrancy guard: prevent infinite loops when other plugins (e.g. markview)
-- react to OptionSet events triggered by nvim_set_hl / nvim_buf_set_extmark
local highlighting = false

---Get the indentation level of a line (in columns, expanding tabs)
---@param line string
---@return number
local function get_indent_level(line)
	local indent_str = line:match("^(%s*)")
	if not indent_str then
		return 0
	end
	-- Expand tabs to columns using buffer's tabstop setting
	local cols = 0
	local tabstop = vim.bo.tabstop or 8
	for i = 1, #indent_str do
		if indent_str:sub(i, i) == "\t" then
			cols = cols + (tabstop - (cols % tabstop))
		else
			cols = cols + 1
		end
	end
	return cols
end

---Parse a line to determine if it's a task and its completion status
---@param line string
---@return {is_task: boolean, completed: boolean}
local function parse_task(line)
	-- Match checkbox formats: - [ ], * [ ], + [ ] (and completed variants)
	local checkbox = line:match("^%s*[%-%*%+]%s*(%[[ xX><]%])")
	if not checkbox then
		return { is_task = false, completed = false }
	end

	-- [x], [X], [>], [<] all count as completed
	local completed = checkbox:match("%[[ ]%]") == nil
	return { is_task = true, completed = completed }
end

---Compute progress for all parent tasks in a set of lines
---@param lines string[]
---@return table[] Array of {line_idx: number, done: number, total: number}
function M.compute_progress(lines)
	-- Step 1: Parse all task lines into a flat list
	local tasks = {} -- {line_idx, indent, completed, children_done, children_total}
	for i, line in ipairs(lines) do
		local result = parse_task(line)
		if result.is_task then
			table.insert(tasks, {
				line_idx = i,
				indent = get_indent_level(line),
				completed = result.completed,
				children_done = 0,
				children_total = 0,
			})
		end
	end

	-- Step 2: Reverse-propagate descendant counts
	-- Walk backwards; for each task, find its parent (nearest prior task with
	-- strictly smaller indent) and add this task's counts to the parent.
	for i = #tasks, 1, -1 do
		local task = tasks[i]
		-- Find parent: walk backwards from i-1
		for j = i - 1, 1, -1 do
			if tasks[j].indent < task.indent then
				-- Found parent
				if task.children_total > 0 then
					-- This task is itself a parent — bubble its subtree counts up
					tasks[j].children_done = tasks[j].children_done + task.children_done
					tasks[j].children_total = tasks[j].children_total + task.children_total
				else
					-- Leaf task — count itself
					tasks[j].children_total = tasks[j].children_total + 1
					if task.completed then
						tasks[j].children_done = tasks[j].children_done + 1
					end
				end
				break
			end
		end
	end

	-- Step 3: Collect tasks that have children (parents only)
	local results = {}
	for _, task in ipairs(tasks) do
		if task.children_total > 0 then
			table.insert(results, {
				line_idx = task.line_idx,
				done = task.children_done,
				total = task.children_total,
			})
		end
	end

	return results
end

---Apply progress extmarks to a buffer
---@param bufnr integer Buffer number
function M.highlight_buffer(bufnr)
	if highlighting then
		return
	end

	-- Check if feature is enabled
	local opts = config.options
	if opts.progress and opts.progress.enabled == false then
		return
	end

	if not vim.api.nvim_buf_is_valid(bufnr) then
		return
	end

	highlighting = true

	-- Clear existing progress extmarks
	vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local progress_data = M.compute_progress(lines)

	for _, entry in ipairs(progress_data) do
		local pct = math.floor((entry.done / entry.total) * 100)
		local text = string.format(" %d/%d %d%%", entry.done, entry.total, pct)

		local hl_group
		if pct == 0 then
			hl_group = "YeahNotesProgressNone"
		elseif pct == 100 then
			hl_group = "YeahNotesProgressComplete"
		else
			hl_group = "YeahNotesProgressPartial"
		end

		vim.api.nvim_buf_set_extmark(bufnr, ns_id, entry.line_idx - 1, 0, {
			virt_text = { { text, hl_group } },
			virt_text_pos = "eol",
			priority = 5000,
		})
	end

	highlighting = false
end

---Define highlight groups for progress indicators
function M.setup_highlight_groups()
	local has_termguicolors = vim.o.termguicolors

	if has_termguicolors then
		vim.api.nvim_set_hl(0, "YeahNotesProgressNone", {
			fg = "#ff6b6b",
			italic = true,
			default = false,
		})
		vim.api.nvim_set_hl(0, "YeahNotesProgressPartial", {
			fg = "#ffd93d",
			italic = true,
			default = false,
		})
		vim.api.nvim_set_hl(0, "YeahNotesProgressComplete", {
			fg = "#6bcf7f",
			italic = true,
			default = false,
		})
	else
		vim.api.nvim_set_hl(0, "YeahNotesProgressNone", {
			ctermfg = 203,
			italic = true,
			default = false,
		})
		vim.api.nvim_set_hl(0, "YeahNotesProgressPartial", {
			ctermfg = 221,
			italic = true,
			default = false,
		})
		vim.api.nvim_set_hl(0, "YeahNotesProgressComplete", {
			ctermfg = 114,
			italic = true,
			default = false,
		})
	end
end

---Initialize the progress module
function M.setup()
	M.setup_highlight_groups()
end

return M
