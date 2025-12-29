local M = {}

local api = require("gtranslate.api")
local ui = require("gtranslate.ui")

local languages = {
  auto = "Automatic detection",
  en = "English",
  vi = "Vietnamese",
  ja = "Japanese",
  ko = "Korean",
  fr = "French",
  es = "Spanish",
  zh = "Chinese (Simplified)",
  it = "Italian",
  pt = "Portuguese",
  ru = "Russian",
}

-- Config mặc định
M.languages = languages
M.config = {
  source_lang = "auto",
  target_lang = "vi",
  width_percent = 0.5, -- 50% width
  gemini_api_key = os.getenv("GEMINI_API_KEY"),
  gemini_model = "gemini-2.0-flash",
}

local function normalize_lang(code)
  if not code or type(code) ~= "string" then
    return nil
  end
  return vim.trim(code):lower()
end

local function is_supported_lang(code)
  return languages[code] ~= nil
end

local function format_lang(code)
  local label = languages[code]
  if label then
    return string.format("%s (%s)", code, label)
  end
  return code
end

local function coerce_lang(code, fallback, label)
  local normalized = normalize_lang(code)
  if normalized and is_supported_lang(normalized) then
    return normalized
  end

  if normalized and not is_supported_lang(normalized) then
    vim.notify(
      string.format("Unsupported %s language '%s', falling back to %s", label, normalized, format_lang(fallback)),
      vim.log.levels.WARN
    )
  end

  return fallback
end

local function get_context_filetype()
  local ft = vim.api.nvim_buf_get_option(0, "filetype")
  -- If we are in the translation result window itself, or special windows like noice/notify
  if ft == "markdown" or ft == "noice" or ft == "notify" or ft == "" then
    -- Try to find the previous window or the first normal window
    local prev_win = vim.fn.win_getid(vim.fn.winnr('#'))
    if prev_win ~= 0 then
      local prev_buf = vim.api.nvim_win_get_buf(prev_win)
      local prev_ft = vim.api.nvim_buf_get_option(prev_buf, "filetype")
      if prev_ft ~= "" and prev_ft ~= "noice" and prev_ft ~= "markdown" then
        return prev_ft
      end
    end

    -- Fallback: look for any normal buffer
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local buf = vim.api.nvim_win_get_buf(win)
      local buftype = vim.api.nvim_buf_get_option(buf, "buftype")
      local win_config = vim.api.nvim_win_get_config(win)
      if buftype == "" and win_config.relative == "" then
        return vim.api.nvim_buf_get_option(buf, "filetype")
      end
    end
  end
  return ft
end

local function wrap_for_translation(content, filetype)
  if not filetype or filetype == "" then
    return content
  end
  return string.format("```%s\n%s\n```", filetype, content)
end

-- Lấy text được chọn trong visual mode
local function get_visual_selection()
  -- Use getregion if available (Neovim 0.10+)
  if vim.fn.getregion then
    local s_pos = vim.fn.getpos("'<")
    local e_pos = vim.fn.getpos("'>")
    local mode = vim.fn.visualmode()
    if s_pos[2] ~= 0 and e_pos[2] ~= 0 then
      local region = vim.fn.getregion(s_pos, e_pos, { type = mode })
      if #region > 0 then
        return table.concat(region, "\n")
      end
    end
  end

  -- Fallback for older Neovim or if getregion fails
  local _, srow, scol = unpack(vim.fn.getpos("'<"))
  local _, erow, ecol = unpack(vim.fn.getpos("'>"))

  if srow == 0 or erow == 0 then
    return ""
  end

  if srow > erow or (srow == erow and scol > ecol) then
    srow, erow, scol, ecol = erow, srow, ecol, scol
  end

  local lines = vim.api.nvim_buf_get_lines(0, srow - 1, erow, false)
  if #lines == 0 then
    return ""
  end

  -- If ecol is very large (visual line mode), cap it to the line length
  -- except that string.sub handles large numbers fine.
  if #lines == 1 then
    lines[1] = string.sub(lines[1], scol, ecol)
  else
    lines[1] = string.sub(lines[1], scol)
    lines[#lines] = string.sub(lines[#lines], 1, ecol)
  end

  return table.concat(lines, "\n")
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

function M.translate(opts)
  local text = get_visual_selection()
  local source_ft = get_context_filetype()

  if text == "" then
    vim.notify("No text selected", vim.log.levels.WARN)
    return
  end

  local source = coerce_lang(opts and opts.source, M.config.source_lang, "source")
  local target = coerce_lang(opts and opts.target, M.config.target_lang, "target")

  ui.show_result("Translating...", M.config.width_percent)

  api.translate(text, source, target, function(result, err)
    if err then
      ui.show_result("Error: " .. err, M.config.width_percent)
    else
      local wrapped_result = wrap_for_translation(result, source_ft)
      ui.show_result(wrapped_result, M.config.width_percent)
    end
  end)
end

function M.ai_translate(opts)
  local text = get_visual_selection()
  local source_ft = get_context_filetype()

  if text == "" then
    vim.notify("No text selected", vim.log.levels.WARN)
    return
  end

  local api_key = (opts and opts.api_key) or M.config.gemini_api_key
  if not api_key or api_key == "" then
    vim.notify("Gemini API key not found. Set GEMINI_API_KEY env or pass it in setup()", vim.log.levels.ERROR)
    return
  end

  local target = coerce_lang(opts and opts.target, M.config.target_lang, "target")
  local target_label = languages[target] or target
  local model = (opts and opts.model) or M.config.gemini_model

  ui.show_result("Translating with Gemini AI...", M.config.width_percent)

  api.ai_translate(text, target_label, api_key, model, function(result, err)
    if err then
      ui.show_result("AI Error: " .. err, M.config.width_percent)
    else
      local wrapped_result = wrap_for_translation(result, source_ft)
      ui.show_result(wrapped_result, M.config.width_percent)
    end
  end)
end

return M

