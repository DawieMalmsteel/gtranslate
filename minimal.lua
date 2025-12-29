local script_path = debug.getinfo(1).source
if script_path:sub(1, 1) == "@" then
  script_path = script_path:sub(2)
end
local repo_root = vim.fn.fnamemodify(script_path, ":p:h")

vim.opt.runtimepath:prepend(repo_root)
package.path = table.concat({
  repo_root .. "/lua/?.lua",
  repo_root .. "/lua/?/init.lua",
  package.path,
}, ";")

local module_path = repo_root .. "/lua/gtranslate/init.lua"
local loader, err = loadfile(module_path)
if not loader then
  error("failed to load gtranslate module: " .. err)
end
local gtranslate = loader()
package.loaded["gtranslate"] = gtranslate
package.loaded["gtranslate.init"] = gtranslate

local plugin_path = repo_root .. "/plugin/gtranslate.lua"
local plugin_loader = loadfile(plugin_path)
if plugin_loader then
  plugin_loader()
else
  vim.api.nvim_create_user_command("Gtrans", function()
    gtranslate.translate()
  end, { desc = "Translate visual selection" })
end
