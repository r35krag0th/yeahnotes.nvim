-- Example Lazy.nvim configuration for yeahnotes.nvim
-- Place this in your ~/.config/nvim/lua/plugins/ directory

return {
	"r35krag0th/yeahnotes.nvim",
	dependencies = {
		"nvim-mini/mini.pick", -- Required for find/grep functionality
	},
	-- Configure plugin options
	opts = {
		root = vim.fn.expand("~/notes"), -- Where to store your notes
		-- Customize keymaps or set to false/nil to disable
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
		},
	},
	-- Lazy-load on these keys
	keys = {
		{ "<localleader>nd", desc = "YeahNotes: Today" },
		{ "<localleader>ny", desc = "YeahNotes: Yesterday" },
		{ "<localleader>nt", desc = "YeahNotes: Tomorrow" },
		{ "<localleader>np", desc = "YeahNotes: Previous day" },
		{ "<localleader>nP", desc = "YeahNotes: Previous (skip empty)" },
		{ "<localleader>nn", desc = "YeahNotes: Next day" },
		{ "<localleader>nN", desc = "YeahNotes: Next (skip empty)" },
		{ "<localleader>nf", desc = "YeahNotes: Find files" },
		{ "<localleader>ng", desc = "YeahNotes: Grep notes" },
		{ "<localleader>nm", desc = "YeahNotes: Migrate tasks to tomorrow" },
		{ "<localleader>nM", desc = "YeahNotes: Migrate and open tomorrow" },
	},
	-- Or lazy-load on commands
	cmd = {
		"YNToday",
		"YNYesterday",
		"YNTomorrow",
		"YNPrevious",
		"YNPreviousSkipEmpty",
		"YNNext",
		"YNNextSkipEmpty",
		"YNFind",
		"YNGrep",
		"YNMigrate",
		"YNMigrateAndOpen",
	},
}
