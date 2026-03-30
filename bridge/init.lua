local config <const> = require("config")

Framework = nil

if not Framework then
  local context <const> = IsDuplicityVersion() and "server" or "client"
  local path <const> = ("bridge/%s/%s"):format(config.framework, context)
  
  local success, result = pcall(require, path)
  if not success then
    error(("Failed to load framework '%s': %s. Please check your config.lua"):format(config.framework, result))
  end
  
  print(("Successfully loaded framework: %s"):format(config.framework))

  Framework = result
end

return Framework