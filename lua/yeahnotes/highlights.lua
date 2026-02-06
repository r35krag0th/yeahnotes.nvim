-- Module for custom syntax highlighting (date tags, due dates, etc.)
local M = {}

-- Namespace for extmarks
local ns_id = vim.api.nvim_create_namespace('yeahnotes_highlights')

---Parse a date string in MM/DD/YYYY format
---@param date_str string Date string like "11/10/2025"
---@return number|nil Timestamp or nil if invalid
local function parse_date(date_str)
  local month, day, year = date_str:match('^(%d+)/(%d+)/(%d+)$')
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
  local now = os.date('*t')
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
local function get_due_date_status(date_timestamp)
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
  -- Due date highlights (stoplight colors)
  vim.api.nvim_set_hl(0, 'YeahNotesDueDateOverdue', { fg = '#ff6b6b', bg = '#3d1f1f', bold = true })
  vim.api.nvim_set_hl(0, 'YeahNotesDueDateToday', { fg = '#ffd93d', bg = '#3d3519', bold = true })
  vim.api.nvim_set_hl(0, 'YeahNotesDueDateUpcoming', { fg = '#6bcf7f', bg = '#1f3d24', bold = true })

  -- Regular date tag highlight (pill/label style)
  vim.api.nvim_set_hl(0, 'YeahNotesDateTag', { fg = '#89b4fa', bg = '#1e2030', bold = true })
end

---Apply highlights to a buffer
---@param bufnr integer Buffer number
function M.highlight_buffer(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  -- Clear existing highlights
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  for line_num, line in ipairs(lines) do
    -- Check if this is a task line with a due date
    local task_match = line:match('^%s*[%-%*%+]%s*%[[ xX><]%]%s*@(%d+/%d+/%d+)')

    if task_match then
      -- This is a due date on a task
      local date_timestamp = parse_date(task_match)
      if date_timestamp then
        local status = get_due_date_status(date_timestamp)
        local hl_group = 'YeahNotesDueDateOverdue'
        local icon = '⚠'

        if status == 'today' then
          hl_group = 'YeahNotesDueDateToday'
          icon = '📅'
        elseif status == 'upcoming' then
          hl_group = 'YeahNotesDueDateUpcoming'
          icon = '📌'
        end

        -- Find the position of the date in the line
        local _, date_start = line:find('@', 1, true)
        if date_start then
          local date_end = date_start + #task_match

          -- Add virtual text with icon before the date
          vim.api.nvim_buf_set_extmark(bufnr, ns_id, line_num - 1, date_start - 1, {
            end_col = date_end,
            hl_group = hl_group,
            virt_text = { { icon .. ' ', hl_group } },
            virt_text_pos = 'inline',
          })
        end
      end
    else
      -- Look for regular date tags (not on tasks)
      local offset = 0
      while true do
        local date_start, date_end, date_str = line:find('@(%d+/%d+/%d+)', offset + 1)
        if not date_start then
          break
        end

        -- Verify it's a valid date
        if parse_date(date_str) then
          -- Add pill-style highlight with calendar icon
          vim.api.nvim_buf_set_extmark(bufnr, ns_id, line_num - 1, date_start - 1, {
            end_col = date_end,
            hl_group = 'YeahNotesDateTag',
            virt_text = { { '📆 ', 'YeahNotesDateTag' } },
            virt_text_pos = 'inline',
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

  -- Highlight on buffer enter and text changes
  vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "TextChanged", "TextChangedI", "InsertLeave" }, {
    group = augroup,
    pattern = "*.md",
    callback = function(args)
      M.highlight_buffer(args.buf)
    end,
    desc = "Highlight YeahNotes date tags",
  })

  -- Re-highlight when opening notes
  vim.api.nvim_create_autocmd("FileType", {
    group = augroup,
    pattern = "markdown",
    callback = function(args)
      M.highlight_buffer(args.buf)
    end,
    desc = "Highlight YeahNotes date tags on markdown files",
  })
end

---Initialize the highlights module
function M.setup()
  M.setup_highlight_groups()
  M.setup_autocommands()
end

return M
