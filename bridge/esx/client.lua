if not GetResourceState("es_extended") == "started" then
	error("es_extended is not started. Please start es_extended before starting juddlie_gungame.")
end

local bridge <const> = {}

---@param message string
---@param notificationType "success" | "error" | "info"
function bridge.notify(message, notificationType)
  lib.notify({ description = message, type = notificationType })
end

return bridge