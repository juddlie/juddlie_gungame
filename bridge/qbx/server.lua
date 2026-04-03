if not GetResourceState("ox_core") == "started" then
	error("ox_core is not started. Please start ox_core before starting juddlie_gungame.")
end

local Qbx <const> = exports["qbx_core"]

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
	local QbxPlayer <const> = Qbx:GetPlayer(playerId)
	if not QbxPlayer then return end
	
	if reward?.item then
		bridge.notify(playerId, ("You received %sx %s for killing an opponent!"):format(reward.amount, reward.item), "success")
		return
	end

	QbxPlayer:AddMoney(playerId, reward.account, reward.amount)
	bridge.notify(playerId, ("You received $%s in your %s account for killing an opponent!"):format(reward.amount, reward.account), "success")
end

---@param playerId number
---@param lobby table
---@param reward table
function bridge.rewardWin(playerId, lobby, reward)
	local QbxPlayer <const> = Qbx:GetPlayer(playerId)
	if not QbxPlayer then return end
	
	if reward?.item then
		bridge.notify(playerId, ("You received %sx %s for winning the match!"):format(reward.amount, reward.item), "success")
		return
	end

	QbxPlayer:AddMoney(playerId, reward.account, reward.amount)
	bridge.notify(playerId, ("You received $%s in your %s account for winning the match!"):format(reward.amount, reward.account), "success")
end
	
return bridge