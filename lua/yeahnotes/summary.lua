-- Module for task summary views (global and local)
local M = {}

local config = require('yeahnotes.config')
local bujo = require('yeahnotes.bujo')

-- Internal state for sidebar
local sidebar_state = {
  bufnr = nil,
  winid = nil,
  source_bufnr = nil,
}

---Parse a single line for task information
---@param line string The line to parse
---@param line_num integer The line number (1-indexed)
---@return table|nil Task info table or nil if not a task
local function parse_task_line(line, line_num)
  -- Match task patterns: - [ ] or * [ ] or + [ ]
  local list_marker, checkbox, task_text = line:match('^%s*([%-%*%+])%s*(%[[ xX><]%])%s*(.*)$')

  if checkbox then
    local is_complete = checkbox:match('[xX]') ~= nil
    local is_migrated = checkbox:match('[><]') ~= nil
    return {
      line_num = line_num,
      checkbox = checkbox,
      text = task_text or '',
      is_complete = is_complete,
      is_migrated = is_migrated,
      full_line = line,
    }
  end

  return nil
end

---Get all tasks from a buffer
---@param bufnr integer Buffer number
---@return table List of task tables
local function get_buffer_tasks(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local tasks = {}

  for i, line in ipairs(lines) do
    local task = parse_task_line(line, i)
    if task then
      table.insert(tasks, task)
    end
  end

  return tasks
end

---Search for incomplete tasks across all notes
---@return table List of results with file, line, and task info
function M.find_global_incomplete_tasks()
  local conf = config.options
  local root = vim.fn.expand(conf.root)
  local results = {}

  -- Use vim.fn.glob to find all markdown files
  local files = vim.fn.glob(root .. '/**/*.md', false, true)

  for _, file in ipairs(files) do
    -- Read file contents
    local lines = vim.fn.readfile(file)

    for i, line in ipairs(lines) do
      local task = parse_task_line(line, i)
      if task and not task.is_complete then
        table.insert(results, {
          file = file,
          line_num = i,
          task = task,
          display = string.format('%s:%d: %s',
            vim.fn.fnamemodify(file, ':~:.'),
            i,
            task.text
          ),
        })
      end
    end
  end

  return results
end

---Show global incomplete tasks in a picker
function M.show_global_incomplete_tasks()
  local has_pick, pick = pcall(require, 'mini.pick')
  if not has_pick then
    vim.notify('mini.pick is required for task summaries', vim.log.levels.ERROR)
    return
  end

  local results = M.find_global_incomplete_tasks()

  if #results == 0 then
    vim.notify('No incomplete tasks found', vim.log.levels.INFO)
    return
  end

  -- Create items for picker
  local items = vim.tbl_map(function(result)
    return result.display
  end, results)

  -- Show picker
  pick.start({
    source = {
      items = items,
      name = 'Incomplete Tasks',
      choose = function(selected)
        if selected then
          -- Find the result for this selection
          local idx = tonumber(selected:match('^(%d+)'))
          if not idx then
            -- Match by display text
            for i, result in ipairs(results) do
              if result.display == selected then
                idx = i
                break
              end
            end
          end

          if idx and results[idx] then
            local result = results[idx]
            -- Open file and jump to line
            vim.cmd('edit ' .. vim.fn.fnameescape(result.file))
            vim.api.nvim_win_set_cursor(0, {result.line_num, 0})
            vim.cmd('normal! zz') -- Center the line
          end
        end
      end,
    },
  })
end

---Render tasks in sidebar buffer
---@param bufnr integer Sidebar buffer number
---@param incomplete_tasks table List of incomplete tasks
---@param complete_tasks table List of complete tasks
---@param migrated_tasks table List of migrated tasks
local function render_sidebar(bufnr, incomplete_tasks, complete_tasks, migrated_tasks)
  local lines = {}
  local task_line_map = {} -- Map sidebar line number to source line number

  -- Header
  table.insert(lines, '# Task Summary')
  table.insert(lines, '')

  -- Incomplete tasks section
  table.insert(lines, '## Incomplete Tasks (' .. #incomplete_tasks .. ')')
  table.insert(lines, '')

  if #incomplete_tasks > 0 then
    for _, task in ipairs(incomplete_tasks) do
      local line_idx = #lines + 1
      table.insert(lines, string.format('☐ %s',
        task.text
      ))
      task_line_map[line_idx] = task.line_num
    end
  else
    table.insert(lines, '(none)')
  end

  table.insert(lines, '')
  table.insert(lines, '## Completed Tasks (' .. #complete_tasks .. ')')
  table.insert(lines, '')

  if #complete_tasks > 0 then
    for _, task in ipairs(complete_tasks) do
      local line_idx = #lines + 1
      table.insert(lines, string.format('☑ %s',
        task.text
      ))
      task_line_map[line_idx] = task.line_num
    end
  else
    table.insert(lines, '(none)')
  end

  table.insert(lines, '')
  table.insert(lines, '## Migrated Tasks (' .. #migrated_tasks .. ')')
  table.insert(lines, '')

  if #migrated_tasks > 0 then
    for _, task in ipairs(migrated_tasks) do
      local line_idx = #lines + 1
      table.insert(lines, string.format('⇨ %s',
        task.text
      ))
      task_line_map[line_idx] = task.line_num
    end
  else
    table.insert(lines, '(none)')
  end

  -- Make buffer modifiable temporarily
  vim.api.nvim_set_option_value('modifiable', true, { buf = bufnr })

  -- Set lines
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

  -- Clear existing virtual text
  local ns_id = vim.api.nvim_create_namespace('yeahnotes_sidebar')
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

  -- Add virtual text for line numbers
  for sidebar_line, source_line in pairs(task_line_map) do
    vim.api.nvim_buf_set_extmark(bufnr, ns_id, sidebar_line - 1, 0, {
      virt_text = { { 'L' .. source_line, 'Comment' } },
      virt_text_pos = 'right_align',
    })
  end

  -- Store the mapping for jump functionality
  vim.b[bufnr].yeahnotes_task_line_map = task_line_map

  -- Make buffer read-only
  vim.api.nvim_set_option_value('modifiable', false, { buf = bufnr })
end

---Jump to task in source buffer from sidebar
---@param source_bufnr integer Source buffer number
---@param sidebar_bufnr integer Sidebar buffer number
local function jump_to_task_from_sidebar(source_bufnr, sidebar_bufnr)
  -- Get current line in sidebar
  local cursor = vim.api.nvim_win_get_cursor(0)
  local sidebar_line = cursor[1]

  -- Get the mapping
  local task_line_map = vim.b[sidebar_bufnr].yeahnotes_task_line_map

  if not task_line_map or not task_line_map[sidebar_line] then
    return -- Not a task line
  end

  local source_line = task_line_map[sidebar_line]

  -- Find the window with source buffer
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == source_bufnr then
      vim.api.nvim_set_current_win(win)
      vim.api.nvim_win_set_cursor(win, {source_line, 0})
      vim.cmd('normal! zz')
      return
    end
  end

  vim.notify('Source buffer not visible', vim.log.levels.WARN)
end

---Create or update the sidebar for current buffer
---@param source_bufnr integer|nil Buffer to show tasks from (default: current buffer)
local function create_or_update_sidebar(source_bufnr)
  source_bufnr = source_bufnr or vim.api.nvim_get_current_buf()

  -- Get tasks from source buffer
  local all_tasks = get_buffer_tasks(source_bufnr)
  local incomplete_tasks = vim.tbl_filter(function(t) return not t.is_complete and not t.is_migrated end, all_tasks)
  local complete_tasks = vim.tbl_filter(function(t) return t.is_complete end, all_tasks)
  local migrated_tasks = vim.tbl_filter(function(t) return t.is_migrated end, all_tasks)

  -- If sidebar exists and is visible, update it
  if sidebar_state.bufnr and vim.api.nvim_buf_is_valid(sidebar_state.bufnr) then
    render_sidebar(sidebar_state.bufnr, incomplete_tasks, complete_tasks, migrated_tasks)
    sidebar_state.source_bufnr = source_bufnr
    return
  end

  -- Create new sidebar buffer
  local bufnr = vim.api.nvim_create_buf(false, true)
  sidebar_state.bufnr = bufnr
  sidebar_state.source_bufnr = source_bufnr

  -- Set buffer options
  vim.api.nvim_set_option_value('buftype', 'nofile', { buf = bufnr })
  vim.api.nvim_set_option_value('bufhidden', 'hide', { buf = bufnr })
  vim.api.nvim_set_option_value('swapfile', false, { buf = bufnr })
  vim.api.nvim_set_option_value('filetype', 'markdown', { buf = bufnr })
  vim.api.nvim_buf_set_name(bufnr, 'YeahNotes: Task Summary')

  -- Render content
  render_sidebar(bufnr, incomplete_tasks, complete_tasks, migrated_tasks)

  -- Create split window
  vim.cmd('vertical rightbelow 40vsplit')
  local winid = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(winid, bufnr)
  sidebar_state.winid = winid

  -- Set window options
  vim.api.nvim_set_option_value('wrap', true, { win = winid })
  vim.api.nvim_set_option_value('number', false, { win = winid })
  vim.api.nvim_set_option_value('relativenumber', false, { win = winid })
  vim.api.nvim_set_option_value('signcolumn', 'no', { win = winid })
  vim.api.nvim_set_option_value('breakindent', true, { win = winid })
  vim.api.nvim_set_option_value('breakindentopt', 'shift:2', { win = winid })
  vim.api.nvim_set_option_value('linebreak', true, { win = winid })

  -- Set up keymaps for sidebar
  local opts = { buffer = bufnr, noremap = true, silent = true }
  vim.keymap.set('n', '<CR>', function()
    jump_to_task_from_sidebar(source_bufnr, bufnr)
  end, opts)
  vim.keymap.set('n', 'q', function()
    M.close_sidebar()
  end, opts)

  -- Return to source window
  vim.cmd('wincmd p')
end

---Show local task sidebar for current buffer
function M.show_local_sidebar()
  local bufnr = vim.api.nvim_get_current_buf()
  create_or_update_sidebar(bufnr)
end

---Toggle the local task sidebar
function M.toggle_local_sidebar()
  -- Check if sidebar is currently visible
  if sidebar_state.winid and vim.api.nvim_win_is_valid(sidebar_state.winid) then
    M.close_sidebar()
  else
    M.show_local_sidebar()
  end
end

---Close the sidebar
function M.close_sidebar()
  if sidebar_state.winid and vim.api.nvim_win_is_valid(sidebar_state.winid) then
    vim.api.nvim_win_close(sidebar_state.winid, true)
    sidebar_state.winid = nil
  end
end

---Update sidebar if it's visible
function M.update_sidebar_if_visible()
  if sidebar_state.winid and vim.api.nvim_win_is_valid(sidebar_state.winid) then
    local current_buf = vim.api.nvim_get_current_buf()

    -- Only update if we're in the source buffer
    if current_buf == sidebar_state.source_bufnr then
      create_or_update_sidebar(current_buf)
    end
  end
end

return M
