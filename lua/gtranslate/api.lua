local M = {}

local uv = vim.loop

local function build_cmd(text, source_lang, target_lang)
  local base_url = "https://translate.googleapis.com/translate_a/single"
  return {
    "curl",
    "-s",
    "-G",
    base_url,
    "--data-urlencode",
    "q=" .. text,
    "--data-urlencode",
    "client=gtx",
    "--data-urlencode",
    "sl=" .. source_lang,
    "--data-urlencode",
    "tl=" .. target_lang,
    "--data-urlencode",
    "dt=t",
  }
end

local function parse_translation(raw)
  if raw == "" then
    return nil, "empty response"
  end

  local ok, decoded = pcall(vim.fn.json_decode, raw)
  if not ok or type(decoded) ~= "table" or type(decoded[1]) ~= "table" then
    return nil, "invalid response"
  end

  local parts = {}
  for _, entry in ipairs(decoded[1]) do
    local chunk = entry[1]
    if chunk and chunk ~= vim.NIL then
      table.insert(parts, chunk)
    end
  end

  if #parts == 0 then
    return nil, "no translation returned"
  end

  return table.concat(parts), nil
end

function M.translate(text, source_lang, target_lang, callback)
  if not text or text == "" then
    callback(nil, "no text provided")
    return
  end

  local cmd = build_cmd(text, source_lang, target_lang)
  local stdout = {}

  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      if not data or data[1] == "" then
        return
      end
      stdout[#stdout + 1] = table.concat(data, "")
    end,
    on_stderr = function(_, data)
      if data and data[1] and data[1] ~= "" then
        stdout[#stdout + 1] = table.concat(data, "")
      end
    end,
    on_exit = function(_, exit_code)
      local raw = table.concat(stdout, "")
      if exit_code ~= 0 or raw == "" then
        callback(nil, "translation request failed")
        return
      end

      local translated, err = parse_translation(raw)
      if err then
        callback(nil, err)
        return
      end

      callback(translated, nil)
    end,
  })
end

local function parse_gemini_response(raw)
  if raw == "" then
    return nil, "empty response"
  end

  local ok, decoded = pcall(vim.fn.json_decode, raw)
  if not ok then
    return nil, "invalid JSON response"
  end

  if decoded.error then
    return nil, decoded.error.message or "Gemini API error"
  end

  if not decoded.candidates or #decoded.candidates == 0 then
    return nil, "no translation candidates returned"
  end

  local candidate = decoded.candidates[1]
  if not candidate.content or not candidate.content.parts or #candidate.content.parts == 0 then
    return nil, "invalid response format"
  end

  local text = candidate.content.parts[1].text
  
  -- Ultimate stripping: remove all leading/trailing fences and empty lines
  local function ultimate_clean(s)
    s = vim.trim(s)
    local changed = true
    while changed do
      changed = false
      -- Strip leading fence: ```lang\n or just ```
      if s:sub(1, 3) == "```" then
        local next_nl = s:find("\n")
        if next_nl then
          s = s:sub(next_nl + 1)
        else
          s = s:sub(4)
        end
        s = vim.trim(s)
        changed = true
      end
      -- Strip trailing fence: \n``` or just ```
      if s:sub(-3) == "```" then
        -- Handle case where there might be a newline before the closing fence
        if s:sub(-4, -4) == "\n" then
          s = s:sub(1, -5)
        else
          s = s:sub(1, -4)
        end
        s = vim.trim(s)
        changed = true
      end
    end
    return s
  end
  
  return ultimate_clean(text), nil
end

function M.ai_translate(text, target_lang, api_key, callback)
  if not text or text == "" then
    callback(nil, "no text provided")
    return
  end

  local prompt = string.format([[
Translate the following text to %s. 
Rules:
1. ONLY output the translation.
2. DO NOT use markdown code blocks or backticks to wrap your output.
3. DO NOT include any introductory or explanatory text.
]], target_lang)
  local payload = {
    contents = {
      {
        parts = {
          { text = prompt .. "\n\n" .. text }
        }
      }
    }
  }

  local url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=" .. api_key
  local cmd = {
    "curl",
    "-s",
    "-X", "POST",
    url,
    "-H", "Content-Type: application/json",
    "-d", vim.fn.json_encode(payload)
  }

  local stdout = {}
  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      if data then
        for _, line in ipairs(data) do
          table.insert(stdout, line)
        end
      end
    end,
    on_exit = function(_, exit_code)
      local raw = table.concat(stdout, "\n")
      if exit_code ~= 0 then
        callback(nil, "Gemini request failed")
        return
      end

      local translated, err = parse_gemini_response(raw)
      if err then
        callback(nil, err)
      else
        callback(translated, nil)
      end
    end,
  })
end

return M
