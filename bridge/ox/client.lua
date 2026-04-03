if not GetResourceState("ox_core") == "started" then
	error("ox_core is not started. Please start ox_core before starting juddlie_gungame.")
end

local bridge <const> = {}

---@param message string
---@param notificationType "success" | "error" | "info"
function bridge.notify(message, notificationType)
  lib.notify({ description = message, type = notificationType })
end

return bridge