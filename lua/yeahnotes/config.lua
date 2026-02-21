local M = {}

---@class yeahnotes.Config
---@field root string Root directory for notes
---@field keymap table Keymap configuration
---@field template? function|string|boolean Template for new journal entries (function, string, or false to disable)
M.defaults = {
	root = vim.fn.expand("~/notes"),
	keymap = {
		yesterday = "<localleader>ny",
		today = "<localleader>nd",
		tomorrow = "<localleader>nt",
		previous_no_skip = "<localleader>np",
		previous_with_skip = "<localleader>nP",
		next_no_skip = "<localleader>nn",
		next_with_skip = "<localleader>nN",
		find = "<localleader>nf",
		grep = "<localleader>ng",
		migrate = "<localleader>nm",
		migrate_and_open = "<localleader>nM",
		global_tasks = "<localleader>nT",
		toggle_task_sidebar = "<localleader>ns",
		toggle_checkbox = "<localleader>nx",
	},
	-- Template can be a function that receives date info, a string, or false to disable
	template = function(date_info)
		return string.format(
			[[# %s

## ☀️ Start of Day
### How are you feeling this morning?


### What is your plan for today?


## 🧠 Daily Enrichment


## 🌞 Pre-Lunch


## 🌝 Post-Lunch


## 🌚 End of Day
### What did you accomplish?


### What are you going to work on tomorrow?


### How do you feel about your day?


]],
			os.date("%A, %B %d, %Y", date_info.date)
		)
	end,
}

---@type yeahnotes.Config
M.options = nil

---@param options? yeahnotes.Config
function M.setup(options)
	M.options = vim.tbl_deep_extend("force", {}, M.defaults, options)
end

---@param options? yeahnotes.Config
function M.extend(options)
	return options and vim.tbl_deep_extend("force", {}, M.options, options)
end

setmetatable(M, {
	__index = function(_, k)
		if k == "options" then
			return M.defaults
		end
	end,
})

return M
