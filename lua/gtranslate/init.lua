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

local function wrap_for_translation(content, filetype)
  if not filetype or filetype == "" then
    return content
  end
  return string.format("```%s\n%s\n```", filetype, content)
end

-- Lấy text được chọn trong visual mode
local function get_visual_selection()
  local _, srow, scol = unpack(vim.fn.getpos("'<"))
  local _, erow, ecol = unpack(vim.fn.getpos("'>"))

  if srow > erow or (srow == erow and scol > ecol) then
    srow, erow = erow, srow
    scol, ecol = ecol, scol
  end

  local lines = vim.api.nvim_buf_get_lines(0, srow - 1, erow, false)

  if #lines == 0 then
    return ""
  end

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
  local source_ft = vim.api.nvim_buf_get_option(0, "filetype")

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

return M

