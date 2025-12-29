local M = {}

local api = vim.api
local state = {
  win = nil,
  buf = nil,
}

local function set_buffer_lines(buf, content)
  api.nvim_buf_set_option(buf, "modifiable", true)
  api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(content, "\n"))
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
  local columns = api.nvim_get_option("columns")
  local target_width = math.floor(columns * width_percent)
  api.nvim_command("botright vsplit")
  local win = api.nvim_get_current_win()
  api.nvim_win_set_width(win, target_width)
  api.nvim_win_set_buf(win, buf)
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
  vim.keymap.set("n", "q", function()
    close_state()
  end, { buffer = api.nvim_win_get_buf(win), nowait = true, silent = true })
end

function M.show_result(content, width_percent)
  if state.win and api.nvim_win_is_valid(state.win) and state.buf and api.nvim_buf_is_valid(state.buf) then
    set_buffer_lines(state.buf, content)
    api.nvim_win_set_width(state.win, math.floor(api.nvim_get_option("columns") * width_percent))
    return
  end

  local buf = create_buffer(content)
  local win = show_split(buf, width_percent)
  state.win = win
  state.buf = buf
  attach_quit_key(win)
end

return M
