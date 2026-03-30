local config = {}

---@type "esx" | "ox"
config.framework = "esx"

config.weapons = {
  [0] = { label = "AP Pistol", hash = `WEAPON_APPISTOL` },
  [1] = { label = "Carbine Rifle", hash = `WEAPON_CARBINERIFLE` }
}

---@param message string
---@param type "success" | "error" | "info"
---@param source number?
config.notify = function(message, type, source)
  if IsDuplicityVersion() and source then
    return lib.notify(source, { description = message, type = type })
  end

  lib.notify({ description = message, type = type })
end

return config