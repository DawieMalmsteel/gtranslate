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

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

function M.translate(opts)
  local text = get_visual_selection()

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
      ui.show_result(result, M.config.width_percent)
    end
  end)
end

return M
