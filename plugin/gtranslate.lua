local gtranslate = require("gtranslate")

gtranslate.setup()

vim.api.nvim_create_user_command("Gtrans", function(opts)
  local args = vim.split(opts.args or "", "%s+", { trimempty = true })
  local override_source = args[1]
  local override_target = args[2]
  gtranslate.translate({ source = override_source, target = override_target })
end, {
  range = 0,
  nargs = "*",
  desc = "Translate visual selection (optional source/target codes)",
})

vim.api.nvim_create_user_command("Atrans", function(opts)
  local args = vim.split(opts.args or "", "%s+", { trimempty = true })
  local override_target = args[1]
  gtranslate.ai_translate({ target = override_target })
end, {
  range = 0,
  nargs = "*",
  desc = "Translate visual selection using Gemini AI (optional target code)",
})
