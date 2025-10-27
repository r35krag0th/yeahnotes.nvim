local yeahnotes = require("yeahnotes")

-- Individual user commands for convenience
vim.api.nvim_create_user_command("YNToday", function()
	yeahnotes.commands.today()
end, { desc = "YeahNotes: Open today's journal" })

vim.api.nvim_create_user_command("YNYesterday", function()
	yeahnotes.commands.yesterday()
end, { desc = "YeahNotes: Open yesterday's journal" })

vim.api.nvim_create_user_command("YNTomorrow", function()
	yeahnotes.commands.tomorrow()
end, { desc = "YeahNotes: Open tomorrow's journal" })

vim.api.nvim_create_user_command("YNPrevious", function()
	yeahnotes.commands.previous()
end, { desc = "YeahNotes: Go to previous journal entry" })

vim.api.nvim_create_user_command("YNPreviousSkipEmpty", function()
	yeahnotes.commands.previous_skip_empty()
end, { desc = "YeahNotes: Go to previous non-empty journal entry" })

vim.api.nvim_create_user_command("YNNext", function()
	yeahnotes.commands.next()
end, { desc = "YeahNotes: Go to next journal entry" })

vim.api.nvim_create_user_command("YNNextSkipEmpty", function()
	yeahnotes.commands.next_skip_empty()
end, { desc = "YeahNotes: Go to next non-empty journal entry" })

vim.api.nvim_create_user_command("YNFind", function()
	yeahnotes.pickers.find_files()
end, { desc = "YeahNotes: Find files in notes" })

vim.api.nvim_create_user_command("YNGrep", function()
	yeahnotes.pickers.grep()
end, { desc = "YeahNotes: Grep through notes" })

vim.api.nvim_create_user_command("YNMigrate", function()
	yeahnotes.commands.migrate_to_tomorrow()
end, { desc = "YeahNotes: Migrate incomplete tasks to tomorrow" })

vim.api.nvim_create_user_command("YNMigrateAndOpen", function()
	yeahnotes.commands.migrate_and_open()
end, { desc = "YeahNotes: Migrate tasks and open tomorrow's journal" })

vim.api.nvim_create_user_command("YNGlobalTasks", function()
	yeahnotes.commands.show_global_tasks()
end, { desc = "YeahNotes: Show all incomplete tasks globally" })

vim.api.nvim_create_user_command("YNTaskSidebar", function()
	yeahnotes.commands.show_task_sidebar()
end, { desc = "YeahNotes: Show task sidebar for current file" })

vim.api.nvim_create_user_command("YNToggleTaskSidebar", function()
	yeahnotes.commands.toggle_task_sidebar()
end, { desc = "YeahNotes: Toggle task sidebar for current file" })
