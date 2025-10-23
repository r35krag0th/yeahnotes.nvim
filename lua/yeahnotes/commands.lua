local navigation = require("yeahnotes.navigation")
local bujo = require("yeahnotes.bujo")

local M = {}

--- Open today's journal entry
function M.today()
	navigation.date_to_journal(os.time())
end

--- Open yesterday's journal entry
function M.yesterday()
	navigation.relative_to_journal(-1)
end

--- Open tomorrow's journal entry
function M.tomorrow()
	navigation.relative_to_journal(1)
end

--- Navigate to previous journal entry
function M.previous()
	navigation.goto_previous_day(false)
end

--- Navigate to previous non-empty journal entry
function M.previous_skip_empty()
	navigation.goto_previous_day(true)
end

--- Navigate to next journal entry
function M.next()
	navigation.goto_next_day(false)
end

--- Navigate to next non-empty journal entry
function M.next_skip_empty()
	navigation.goto_next_day(true)
end

--- Migrate incomplete tasks to tomorrow
function M.migrate_to_tomorrow()
	bujo.migrate_to_tomorrow({ mark_migrated = true, open_tomorrow = false })
end

--- Migrate incomplete tasks to tomorrow and open tomorrow's journal
function M.migrate_and_open()
	bujo.migrate_to_tomorrow({ mark_migrated = true, open_tomorrow = true })
end

return M
