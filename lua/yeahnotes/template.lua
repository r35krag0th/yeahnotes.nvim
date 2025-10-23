local config = require("yeahnotes.config")

local M = {}

--- Generate template content for a journal entry
---@param date osdate The date for the journal entry
---@return string|nil Template content or nil if templates are disabled
function M.render(date)
	local template_config = config.options.template

	-- Templates disabled
	if template_config == false or template_config == nil then
		return nil
	end

	-- Build date info for the template
	local date_info = {
		date = date,
		year = tonumber(os.date("%Y", date)),
		month = tonumber(os.date("%m", date)),
		day = tonumber(os.date("%d", date)),
		weekday = os.date("%A", date),
		month_name = os.date("%B", date),
		formatted = os.date("%Y-%m-%d", date),
		formatted_long = os.date("%A, %B %d, %Y", date),
	}

	-- Template is a function
	if type(template_config) == "function" then
		local ok, result = pcall(template_config, date_info)
		if not ok then
			vim.notify("Error rendering template: " .. tostring(result), vim.log.levels.ERROR)
			return nil
		end
		return result
	end

	-- Template is a string (can include placeholders)
	if type(template_config) == "string" then
		local content = template_config
		-- Replace common placeholders
		content = content:gsub("{date}", date_info.formatted)
		content = content:gsub("{date_long}", date_info.formatted_long)
		content = content:gsub("{year}", tostring(date_info.year))
		content = content:gsub("{month}", string.format("%02d", date_info.month))
		content = content:gsub("{day}", string.format("%02d", date_info.day))
		content = content:gsub("{weekday}", date_info.weekday)
		content = content:gsub("{month_name}", date_info.month_name)
		return content
	end

	return nil
end

--- Check if a file exists and is not empty
---@param file_path string Path to check
---@return boolean True if file exists and has content
function M.file_has_content(file_path)
	local file = io.open(file_path, "r")
	if not file then
		return false
	end

	local content = file:read("*all")
	file:close()

	return content and #vim.trim(content) > 0
end

--- Apply template to a file if it doesn't exist or is empty
---@param file_path string Path to the file
---@param date osdate Date for the journal entry
---@return boolean True if template was applied
function M.apply_if_new(file_path, date)
	-- Only apply template if file doesn't exist or is empty
	if M.file_has_content(file_path) then
		return false
	end

	local content = M.render(date)
	if not content then
		return false
	end

	-- Write template to file
	local file = io.open(file_path, "w")
	if file then
		file:write(content)
		file:close()
		return true
	else
		vim.notify("Failed to write template to " .. file_path, vim.log.levels.ERROR)
		return false
	end
end

return M
