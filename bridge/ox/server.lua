if not GetResourceState("ox_core") == "started" then
	error("ox_core is not started. Please start ox_core before starting juddlie_gungame.")
end

local bridge <const> = {}

---@param playerId number
---@return string
function bridge.getName(playerId)
	return GetPlayerName(playerId) or ("Player %s"):format(playerId)
end

---@param playerId number
---@param message string
---@param notificationType "success" | "error" | "info"
function bridge.notify(playerId, message, notificationType)
	lib.notify(playerId, { description = message, type = notificationType })
end

---@param playerId number
---@param lobby table
---@param reward table
function bridge.rewardKill(playerId, lobby, reward)
	
end

---@param playerId number
---@param lobby table
---@param reward table
function bridge.rewardWin(playerId, lobby, reward)

end

return bridge