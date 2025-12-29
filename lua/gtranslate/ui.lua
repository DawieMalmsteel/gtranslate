local M = {}

local api = vim.api
local state = {
  win = nil,
  buf = nil,
}

local function set_buffer_lines(buf, content)
  api.nvim_buf_set_option(buf, "modifiable", true)
  local lines = vim.split(vim.trim(content), "\n", { trimempty = false })
  api.nvim_buf_set_lines(buf, 0, -1, false, lines)
end

local function create_buffer(content)
  local buf = api.nvim_create_buf(false, true)
  api.nvim_buf_set_option(buf, "filetype", "markdown")
  api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  api.nvim_buf_set_option(buf, "buftype", "nofile")
  api.nvim_buf_set_option(buf, "modifiable", true)
  set_buffer_lines(buf, content)
  return buf
end


local function show_split(buf, width_percent)
  -- If we are in a floating window, find a target window that is not a float
  local current_win = api.nvim_get_current_win()
  local config = api.nvim_win_get_config(current_win)
  
  if config and config.relative ~= "" then
    -- We are in a float. Let's find a normal window.
    local wins = api.nvim_list_wins()
    local target_win = nil
    for _, w in ipairs(wins) do
      local c = api.nvim_win_get_config(w)
      if c.relative == "" then
        target_win = w
        break
      end
    end
    
    if target_win then
      api.nvim_set_current_win(target_win)
    else
      -- No normal window found? This is weird, but let's try to proceed.
    end
  end

  local columns = api.nvim_get_option("columns")
  local target_width = math.floor(columns * width_percent)
  
  -- Try to split. Use pcall to catch errors in weird window states.
  local success, err = pcall(vim.cmd, "botright vsplit")
  if not success then
    vim.notify("Could not create split: " .. tostring(err), vim.log.levels.ERROR)
    return nil
  end
  
  local win = api.nvim_get_current_win()
  if not win or not api.nvim_win_is_valid(win) then
    return nil
  end
  
  -- Extra safety: set_width and set_buf can also fail if the win is locked
  pcall(api.nvim_win_set_width, win, target_width)
  local ok = pcall(api.nvim_win_set_buf, win, buf)
  if not ok then
    return nil
  end
  
  return win
end

local function close_state()
  if state.win and api.nvim_win_is_valid(state.win) then
    api.nvim_win_close(state.win, true)
  end
  state.win = nil
  state.buf = nil
end

local function attach_quit_key(win)
  if not win or not api.nvim_win_is_valid(win) then return end
  
  local ok, buf = pcall(api.nvim_win_get_buf, win)
  if not ok or not buf or not api.nvim_buf_is_valid(buf) then
    return
  end
  
  vim.keymap.set("n", "q", function()
    close_state()
  end, { buffer = buf, nowait = true, silent = true })
end

function M.show_result(content, width_percent)
  if state.win and api.nvim_win_is_valid(state.win) and state.buf and api.nvim_buf_is_valid(state.buf) then
    set_buffer_lines(state.buf, content)
    api.nvim_win_set_width(state.win, math.floor(api.nvim_get_option("columns") * width_percent))
    return
  end

  local buf = create_buffer(content)
  local win = show_split(buf, width_percent)
  if not win then
    -- If split failed, we could try a floating window or at least not crash
    return
  end
  state.win = win
  state.buf = buf
  attach_quit_key(win)
end

return M
