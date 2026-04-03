local bridge <const> = require("bridge")
local config <const> = require("config")

local state <const> = {
  lobbies = {},
  playerLobby = {},
  playerState = {},
}

---@param playerId number
---@return boolean
function state.isOnline(playerId)
  return GetPlayerName(playerId) ~= nil
end

---@param playerId number
---@return string
function state.getName(playerId)
  return bridge.getName(playerId)
end

---@param lobby table
---@return number
function state.countMembers(lobby)
  local count = 0

  for _ in pairs(lobby.members) do
    count = count + 1
  end

  return count
end

---@param lobby table
---@return number
function state.countActiveMembers(lobby)
  local count = 0

  for _, member in pairs(lobby.members) do
    if not member.spectator then
      count = count + 1
    end
  end

  return count
end

---@param lobby table
---@return number
function state.countSpectators(lobby)
  local count = 0

  for _, member in pairs(lobby.members) do
    if member.spectator then
      count = count + 1
    end
  end

  return count
end

---@param selectedWeapons any
---@return number[]
function state.getWeapons(selectedWeapons)
  local weaponIndices <const> = {}
  local seen <const> = {}

  if type(selectedWeapons) ~= "table" then
    return weaponIndices
  end

  for _, value in ipairs(selectedWeapons) do
    local weaponIndex <const> = tonumber(value)
    if weaponIndex and not seen[weaponIndex] and config.weapons[weaponIndex] then
      seen[weaponIndex] = true
      weaponIndices[#weaponIndices + 1] = weaponIndex
    end
  end

  table.sort(weaponIndices)

  return weaponIndices
end

---@param playerId number
---@return { x: number, y: number, z: number, heading: number }
function state.getSpawn(playerId)
  local ped <const> = GetPlayerPed(playerId)
  local coords <const> = GetEntityCoords(ped)

  return {
    x = coords.x,
    y = coords.y,
    z = coords.z,
    heading = GetEntityHeading(ped),
  }
end

---@param lobby table
---@param tier number
---@return table?
function state.getWeapon(lobby, tier)
  local weaponId <const> = lobby.weaponIndices[tier]

  return weaponId and config.weapons[weaponId] or nil
end

---@param lobby table
---@param viewerId number
---@return table
function state.getLobby(lobby, viewerId)
  local viewerLobby <const> = state.playerLobby[viewerId]
  local viewerInLobby <const> = viewerLobby ~= nil
  local totalMembers <const> = state.countMembers(lobby)
  local activeMembers <const> = state.countActiveMembers(lobby)
  local spectatorCount <const> = totalMembers - activeMembers

  return {
    name = lobby.name,
    owner = lobby.owner,
    ownerName = lobby.ownerName,
    maxPlayers = lobby.maxPlayers,
    memberCount = activeMembers,
    totalMembers = totalMembers,
    spectatorCount = spectatorCount,
    started = lobby.started,
    private = lobby.private,
    killsPerTier = lobby.killsPerTier,
    weaponCount = #lobby.weaponIndices,
    isOwner = viewerId == lobby.owner,
    isMember = viewerLobby == lobby.name,
    canJoin = not lobby.started and activeMembers < lobby.maxPlayers and not viewerInLobby,
    canSpectate = config.game.allowSpectate and lobby.started and not viewerInLobby and (not lobby.private or viewerId == lobby.owner),
  }
end

---@param lobby table
---@return table[]
function state.getMembers(lobby)
  local members <const> = {}

  for playerId, member in pairs(lobby.members) do
    members[#members + 1] = {
      source = playerId,
      name = member.name or state.getName(playerId),
      spectator = member.spectator == true,
      isOwner = playerId == lobby.owner,
    }
  end

  table.sort(members, function(left, right)
    return left.name < right.name
  end)

  return members
end

---@param lobby table
---@param playerId number
---@param overrides table?
---@return table
function state.getState(lobby, playerId, overrides)
  local member <const> = lobby.members[playerId] or {}
  local player <const> = state.playerState[playerId] or {}
  local totalMembers <const> = state.countMembers(lobby)
  local activeMembers <const> = state.countActiveMembers(lobby)
  local spectatorCount <const> = totalMembers - activeMembers

  local payload <const> = {
    lobbyName = lobby.name,
    owner = lobby.owner,
    ownerName = lobby.ownerName,
    maxPlayers = lobby.maxPlayers,
    memberCount = activeMembers,
    totalMembers = totalMembers,
    spectatorCount = spectatorCount,
    started = lobby.started,
    private = lobby.private,
    killsPerTier = lobby.killsPerTier,
    weaponIndices = lobby.weaponIndices,
    spawn = lobby.spawn,
    tier = player.tier or 1,
    spectator = member.spectator == true,
  }

  if overrides then
    for key, value in pairs(overrides) do
      payload[key] = value
    end
  end

  return payload
end

---@param playerId number
---@param lobby table
---@param overrides table?
function state.sendState(playerId, lobby, overrides)
  if not state.isOnline(playerId) then
    return
  end

  TriggerClientEvent("gungame:client:updateLobbyState", playerId, state.getState(lobby, playerId, overrides))
end

---@param lobby table
---@param message string
---@param notificationType "success" | "error" | "info"
function state.notifyMembers(lobby, message, notificationType)
  for playerId in pairs(lobby.members) do
    if state.isOnline(playerId) then
      bridge.notify(playerId, message, notificationType)
    end
  end
end

---@param lobby table
---@param excludePlayerId number?
---@return number?
function state.getSpectateTarget(lobby, excludePlayerId)
  if not lobby.started then return end

  local fallback = nil

  for playerId, member in pairs(lobby.members) do
    if playerId ~= excludePlayerId and not member.spectator and state.isOnline(playerId) then
      fallback = playerId

      if playerId == lobby.owner then
        return playerId
      end
    end
  end

  return fallback
end

---@param lobbyName string
---@param reason string?
function state.clearLobby(lobbyName, reason)
  local lobby <const> = state.lobbies[lobbyName]
  if not lobby then
    return
  end

  for playerId in pairs(lobby.members) do
    state.playerLobby[playerId] = nil
    state.playerState[playerId] = nil

    if state.isOnline(playerId) then
      TriggerClientEvent("gungame:client:clearLobbyState", playerId, {
        message = reason or "The lobby has been closed",
      })
    end
  end

  state.lobbies[lobbyName] = nil
end

---@param lobby table
---@param playerId number
---@param spectator boolean
function state.addPlayer(lobby, playerId, spectator)
  lobby.members[playerId] = {
    name = state.getName(playerId),
    spectator = spectator == true,
  }

  state.playerLobby[playerId] = lobby.name
  state.playerState[playerId] = {
    lobbyName = lobby.name,
    tier = 1,
    kills = 0,
    spectator = spectator == true,
  }
end

---@param playerId number
---@param reason string?
function state.removePlayer(playerId, reason)
  local lobbyName <const> = state.playerLobby[playerId]
  if not lobbyName then
    return
  end

  local lobby <const> = state.lobbies[lobbyName]
  state.playerLobby[playerId] = nil
  state.playerState[playerId] = nil

  if not lobby then
    return
  end

  if lobby.owner == playerId then
    state.clearLobby(lobbyName, reason or "The lobby has been closed")
    return
  end

  lobby.members[playerId] = nil

  if state.isOnline(playerId) then
    TriggerClientEvent("gungame:client:clearLobbyState", playerId, {
      message = reason or "You left the lobby",
    })
  end

  if state.countMembers(lobby) == 0 then
    state.lobbies[lobbyName] = nil
  end
end

---@param lobby table
---@param winnerId number
function state.finishLobby(lobby, winnerId)
  lobby.started = false

  local reward <const> = config.rewards and config.rewards.win or {}
  bridge.rewardWin(winnerId, lobby, reward)

  local winnerName <const> = state.getName(winnerId)
  state.notifyMembers(lobby, ("%s won %s"):format(winnerName, lobby.name), "success")

  for playerId, member in pairs(lobby.members) do
    local player <const> = state.playerState[playerId]
    if player then
      player.kills = 0
      player.tier = 1
    end

    if state.isOnline(playerId) then
      TriggerClientEvent("gungame:client:matchEnded", playerId, {
        lobbyName = lobby.name,
        winnerName = winnerName,
        spectator = member.spectator == true,
      })

      state.sendState(playerId, lobby, {
        started = false,
        tier = 1,
      })
    end
  end
end

return state