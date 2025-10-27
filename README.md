# yeahnotes.nvim

A lightweight, work-friendly Neovim journal plugin with intelligent weekday navigation.

## Features

- **Weekday-Aware Navigation**: Automatically skips weekends when navigating between journal entries
- **BuJo Task Migration**: Migrate incomplete tasks to tomorrow's journal (Bullet Journal style)
- **Task Summary Views**: View incomplete tasks globally across all notes or locally in a sidebar
- **Customizable Templates**: Auto-populate new journal entries with your preferred structure
- **Date-Based Organization**: Clean hierarchical structure (`journal/YYYY/MM/DD.md`)
- **Fast File Finding**: Integrated with [mini.pick](https://github.com/echasnovski/mini.pick) for fuzzy finding and live grep
- **Markdown-Based**: Simple `.md` files, no special syntax required
- **Lazy.nvim Ready**: Built with lazy loading in mind

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "your-username/yeahnotes.nvim",
  dependencies = {
    "echasnovski/mini.pick",  -- Required for find/grep functionality
  },
  opts = {
    root = vim.fn.expand("~/notes"),  -- Default notes directory
  },
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
    { "<localleader>nT", desc = "YeahNotes: Show all incomplete tasks" },
    { "<localleader>ns", desc = "YeahNotes: Toggle task sidebar" },
  },
}
```

## Configuration

### Default Configuration

```lua
require("yeahnotes").setup({
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
  },
})
```

### Custom Configuration

```lua
require("yeahnotes").setup({
  root = vim.fn.expand("~/my-notes"),
  keymap = {
    today = "<leader>jt",
    yesterday = "<leader>jy",
    tomorrow = "<leader>jm",
    -- Set to false or nil to disable specific keymaps
    previous_no_skip = false,
    find = "<leader>jf",
    grep = "<leader>jg",
  },
  -- Custom template (function that receives date_info)
  template = function(date_info)
    return string.format([[# %s

## 🎯 Goals
- [ ]

## 📝 Tasks
- [ ]

## 📅 Meetings


## 💭 Notes


]], date_info.formatted_long)
  end,
})
```

### Template Configuration

yeahnotes.nvim supports customizable templates for new journal entries. Templates are applied automatically when creating a new journal file.

**Template can be:**

1. **A function** that receives `date_info` table:

   ```lua
   template = function(date_info)
     -- date_info contains: date, year, month, day, weekday,
     --                     month_name, formatted, formatted_long
     return "# " .. date_info.formatted_long .. "\n\n"
   end
   ```

2. **A string** with placeholders:

   ```lua
   template = [[# {date_long}

   ## Tasks
   - [ ]

   ## Notes

   ]]
   -- Available placeholders: {date}, {date_long}, {year}, {month},
   --                         {day}, {weekday}, {month_name}
   ```

3. **`false`** to disable templates:

   ```lua
   template = false  -- No templates
   ```

**Default template:**

```lua
template = function(date_info)
  return string.format([[# %s

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


]], os.date("%A, %B %d, %Y", date_info.date))
end
```

## Usage

### Commands

The plugin provides the following user commands:

| Command                | Description                                           |
| ---------------------- | ----------------------------------------------------- |
| `:YNToday`             | Open today's journal entry                            |
| `:YNYesterday`         | Open yesterday's journal entry                        |
| `:YNTomorrow`          | Open tomorrow's journal entry                         |
| `:YNPrevious`          | Navigate to previous journal entry (skips weekends)   |
| `:YNPreviousSkipEmpty` | Navigate to previous non-empty journal entry          |
| `:YNNext`              | Navigate to next journal entry (skips weekends)       |
| `:YNNextSkipEmpty`     | Navigate to next non-empty journal entry              |
| `:YNFind`              | Find files in notes directory                         |
| `:YNGrep`              | Live grep through all notes                           |
| `:YNMigrate`           | Migrate incomplete tasks to tomorrow (marks as `[>]`) |
| `:YNMigrateAndOpen`    | Migrate tasks and open tomorrow's journal             |
| `:YNGlobalTasks`       | Show all incomplete tasks across all notes            |
| `:YNTaskSidebar`       | Show task sidebar for current file                    |
| `:YNToggleTaskSidebar` | Toggle task sidebar for current file                  |

### Default Keymaps

All keymaps use `<localleader>` by default (typically `\` or `,`):

| Keymap            | Action                    |
| ----------------- | ------------------------- |
| `<localleader>nd` | Today                     |
| `<localleader>ny` | Yesterday                 |
| `<localleader>nt` | Tomorrow                  |
| `<localleader>np` | Previous day              |
| `<localleader>nP` | Previous (skip empty)     |
| `<localleader>nn` | Next day                  |
| `<localleader>nN` | Next (skip empty)         |
| `<localleader>nf` | Find files                |
| `<localleader>ng` | Grep notes                  |
| `<localleader>nm` | Migrate tasks to tomorrow   |
| `<localleader>nM` | Migrate and open tomorrow   |
| `<localleader>nT` | Show all incomplete tasks   |
| `<localleader>ns` | Toggle task sidebar         |

## Journal Structure

Notes are organized in a hierarchical date-based structure:

```
~/notes/
 journal/
     2025/
         10/
             20.md  (Wednesday, Oct 20)
             21.md  (Thursday, Oct 21)
             22.md  (Friday, Oct 22)
             23.md  (Monday, Oct 23) -- Weekends are skipped
```

## Intelligent Navigation

The plugin automatically skips Saturdays and Sundays when navigating:

- **Previous/Next**: Moves to the nearest weekday in the specified direction
- **Skip Empty**: Continues navigating until a non-empty file is found
- **From Any Date**: Navigation works from any journal entry, not just today

This makes it perfect for work journals where weekend entries aren't needed.

## BuJo Task Migration

yeahnotes.nvim includes Bullet Journal-inspired task migration features to help you manage incomplete tasks.

### How It Works

When you run `:YNMigrate` (or `<localleader>nm`):

1. **Finds Incomplete Tasks**: Scans the current journal for unchecked tasks
2. **Migrates to Tomorrow**: Appends them to tomorrow's journal under a "Migrated Tasks" section
3. **Marks as Migrated**: Updates the checkbox in the current file from `[ ]` to `[>]`

### Supported Task Formats

The migration supports standard Markdown checkbox formats:

```markdown
- [ ] Incomplete task (will be migrated)
- [x] Completed task (skipped)
- [x] Also completed (skipped)
- [>] Already migrated (skipped)

* [ ] Works with asterisks too

- [ ] And plus signs
```

### Example Workflow

**Today's journal (2025-10-23.md):**

```markdown
## Work Tasks

- [x] Review pull requests
- [ ] Update documentation
- [ ] Fix bug #123

## Notes

Some meeting notes...
```

After running `:YNMigrate`:

**Today's journal (updated):**

```markdown
## Work Tasks

- [x] Review pull requests
- [>] Update documentation
- [>] Fix bug #123

## Notes

Some meeting notes...
```

**Tomorrow's journal (2025-10-24.md):**

```markdown
# Friday, October 24, 2025

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

## Migrated from 2025-10-23

- [ ] Update documentation
- [ ] Fix bug #123
```

**Note:** If tomorrow's journal doesn't exist or is empty, the configured template will be applied first, then migrated tasks are appended under the "Migrated from {date}" section.

### Commands

- `:YNMigrate` / `<localleader>nm` - Migrate tasks and stay in current file
- `:YNMigrateAndOpen` / `<localleader>nM` - Migrate tasks and open tomorrow's journal

## Task Summary Views

yeahnotes.nvim provides two powerful ways to view and manage your tasks: global search across all notes and a local sidebar for the current file.

### Global Task Summary

Use `:YNGlobalTasks` (or `<localleader>nT`) to search for all incomplete tasks across your entire notes directory.

**Features:**
- Searches all `.md` files in your notes directory
- Shows only incomplete tasks (`- [ ]`)
- Displays results in a picker with file paths and line numbers
- Press Enter to jump directly to the task in its file
- Results are automatically centered in the window

**Example:**

```
notes/journal/2025/10/20.md:15: Review Q4 planning docs
notes/journal/2025/10/21.md:23: Schedule team 1:1s
notes/projects/website-redesign.md:42: Update mockups
```

### Local Task Sidebar

Use `:YNToggleTaskSidebar` (or `<localleader>ns`) to open a sidebar showing all tasks in the current file.

**Features:**
- Shows tasks organized into two sections:
  - **Incomplete Tasks**: All unchecked tasks (`- [ ]`)
  - **Completed Tasks**: All checked tasks (`- [x]`, `- [X]`)
- Updates automatically as you edit the file
- Press Enter on any task to jump to that line in the source file
- Press `q` to close the sidebar
- Toggle on/off with the same command

**Example sidebar:**

```markdown
# Task Summary

## Incomplete Tasks (3)

[ ] Review pull requests                                                     L15
[ ] Update documentation                                                     L23
[ ] Fix bug #123                                                             L42

## Completed Tasks (2)

[x] Team standup                                                             L12
[x] Code review for PR #456                                                  L18
```

Line numbers appear as subtle virtual text on the right, keeping the focus on your tasks while maintaining easy navigation.

The sidebar automatically updates whenever you modify tasks in your note, making it easy to track your progress throughout the day.

**Workflow Tip:** Keep the sidebar open while working through your daily tasks. As you check off items, the sidebar updates in real-time, moving completed tasks to the bottom section.

## Recommended Companions

While yeahnotes.nvim works great on its own, these plugins enhance the experience:

- [markview.nvim](https://github.com/OXY2DEV/markview.nvim) - Beautiful Markdown rendering
- [marksman](https://github.com/artempyanykh/marksman) - LSP for Markdown
- [mini.pick](https://github.com/echasnovski/mini.pick) - Required for find/grep features

## Philosophy

yeahnotes.nvim follows these principles:

- **Simplicity First**: Plain Markdown files, no special syntax
- **Work-Focused**: Automatically skips weekends for work journals
- **Fast & Lightweight**: Minimal dependencies, lazy-loadable
- **Integration-Friendly**: Works seamlessly with existing Neovim ecosystem

## Future Plans

- Support for [snacks.nvim](https://github.com/folke/snacks.nvim) as an alternative picker
- Templates for new journal entries
- Quick note capture commands
- Archive/search functionality

## License

MIT

## Acknowledgments

Inspired by [r35.notes](https://github.com/r35krag0th/r35.notes) and [notes.nvim](https://github.com/dhananjaylatkar/notes.nvim).
