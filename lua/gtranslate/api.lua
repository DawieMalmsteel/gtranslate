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

return M
