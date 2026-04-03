local state <const> = require("server.state")

local bridge <const> = require("bridge")
local config <const> = require("config")

---@param lobby table
local function startLobby(lobby)
  lobby.started = true

  local targetServerId <const> = state.getSpectateTarget(lobby, nil)
  for playerId, member in pairs(lobby.members) do
    local payload <const> = state.getState(lobby, playerId, {
      started = true,
      tier = 1,
      spectator = member.spectator == true,
      targetServerId = targetServerId,
    })

    TriggerClientEvent("gungame:client:startMatch", playerId, payload)
  end

  state.notifyMembers(lobby, ("%s started the match"):format(state.getName(lobby.owner)), "success")
end

RegisterNetEvent("gungame:server:startLobby", function()
  local playerId <const> = source
  if not (playerId and state.isOnline(playerId)) then return end

  local lobbyName <const> = state.playerLobby[playerId]
  local lobby <const> = lobbyName and state.lobbies[lobbyName] or nil
  if not lobby then
    bridge.notify(playerId, "You do not own a lobby", "error")
    return
  end

  if lobby.owner ~= playerId then
    bridge.notify(playerId, "Only the lobby owner can start the game", "error")
    return
  end

  if lobby.started then
    bridge.notify(playerId, "That lobby is already running", "error")
    return
  end

  startLobby(lobby)
end)

---@param attackerId number
RegisterNetEvent("gungame:server:reportKill", function(attackerId)
  local victimId <const> = source
  if victimId == 0 or type(attackerId) ~= "number" then
    return
  end

  local victimLobbyName <const> = state.playerLobby[victimId]
  local attackerLobbyName <const> = state.playerLobby[attackerId]
  if victimLobbyName == nil or victimLobbyName ~= attackerLobbyName then
    return
  end

  local lobby <const> = state.lobbies[victimLobbyName]
  local attacker <const> = state.playerState[attackerId]
  local victim <const> = state.playerState[victimId]
  if not lobby or not lobby.started or not attacker or not victim then
    return
  end

  if attacker.spectator or victim.spectator or attackerId == victimId then
    return
  end

  attacker.kills = (attacker.kills or 0) + 1
  bridge.rewardKill(attackerId, lobby, config.rewards.kill)

  if attacker.kills < lobby.killsPerTier then
    bridge.notify(attackerId, ("Kill %d/%d"):format(attacker.kills, lobby.killsPerTier), "info")
    return
  end

  attacker.kills = 0
  attacker.tier = (attacker.tier or 1) + 1

  if attacker.tier > #lobby.weaponIndices then
    state.finishLobby(lobby, attackerId)
    return
  end

  local weapon <const> = state.getWeapon(lobby, attacker.tier)
  if weapon then
    TriggerClientEvent("gungame:client:updateTier", attackerId, {
      lobbyName = lobby.name,
      tier = attacker.tier,
      weaponIndex = lobby.weaponIndices[attacker.tier],
      weaponHash = weapon.hash,
    })
  end
end)

AddEventHandler("playerDropped", function()
  local playerId <const> = source
  
  state.removePlayer(playerId, "A player left the server")
end)