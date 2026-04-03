local state <const> = require("server.state")

local bridge <const> = require("bridge")
local config <const> = require("config")

---@param data { maxPlayers: number, killsPerTier: number, weapons: number[], lobbyName?: string, password?: string, isPrivate?: boolean }
RegisterNetEvent("gungame:server:createLobby", function(data)
  local playerId <const> = source
  if not (playerId and state.isOnline(playerId)) then return end

  if state.playerLobby[playerId] then
    bridge.notify(playerId, "You are already in a lobby", "error")
    return
  end

  local weaponIndices <const> = state.getWeapons(data.weapons)
  if #weaponIndices == 0 then
    bridge.notify(playerId, "Select at least one weapon tier", "error")
    return
  end

  local lobbyName <const> = data.lobbyName ~= "" and data.lobbyName or
    ("%s's Lobby"):format(state.getName(playerId))
   
  if state.lobbies[lobbyName] then
    bridge.notify(playerId, "A lobby with that name already exists", "error")
    return
  end

  local maxPlayers <const> = math.max(1, tonumber(data.maxPlayers) or config.game.defaultMaxPlayers)
  local killsPerTier <const> = math.max(1, tonumber(data.killsPerTier) or config.game.defaultKillsPerTier)
  local isPrivate <const> = data.isPrivate == true
  local password <const> = data.password

  if isPrivate and (password == nil or password == "") then
    bridge.notify(playerId, "Private lobbies need a password", "error")
    return
  end

  local lobby <const> = {
    name = lobbyName,
    owner = playerId,
    ownerName = state.getName(playerId),
    maxPlayers = maxPlayers,
    killsPerTier = killsPerTier,
    weaponIndices = weaponIndices,
    password = isPrivate and password or nil,
    private = isPrivate,
    started = false,
    spawn = state.getSpawn(playerId),
    members = {},
  }

  state.lobbies[lobbyName] = lobby
  state.addPlayer(lobby, playerId, false)

  bridge.notify(playerId, ("You created %s"):format(lobbyName), "success")
  state.sendState(playerId, lobby, {
    started = false,
    tier = 1,
    spectator = false,
  })
end)

---@param lobbyName string
---@param password string?
RegisterNetEvent("gungame:server:joinLobby", function(lobbyName, password)
  local playerId <const> = source
  if not (playerId and state.isOnline(playerId)) then return end

  if state.playerLobby[playerId] then
    bridge.notify(playerId, "You are already in a lobby", "error")
    return
  end

  local lobby <const> = state.lobbies[lobbyName]
  if not lobby then
    bridge.notify(playerId, "Could not find a lobby with that name", "error")
    return
  end

  if lobby.started then
    bridge.notify(playerId, "That lobby has already started", "error")
    return
  end

  if lobby.private and lobby.password ~= password then
    bridge.notify(playerId, "Incorrect lobby password", "error")
    return
  end

  if state.countActiveMembers(lobby) >= lobby.maxPlayers then
    bridge.notify(playerId, "That lobby is full", "error")
    return
  end

  state.addPlayer(lobby, playerId, false)
  
  bridge.notify(playerId, ("You joined %s"):format(lobby.name), "success")
  state.sendState(playerId, lobby, { started = false, tier = 1, spectator = false, })
end)

---@param lobbyName string
RegisterNetEvent("gungame:server:spectateLobby", function(lobbyName)
  local playerId <const> = source
  if not (playerId and state.isOnline(playerId)) then return end

  if not config.game.allowSpectate then
    bridge.notify(playerId, "Spectating is disabled", "error")
    return
  end

  if state.playerLobby[playerId] then
    bridge.notify(playerId, "You are already in a lobby", "error")
    return
  end

  local lobby <const> = state.lobbies[lobbyName]
  if not lobby then
    bridge.notify(playerId, "Could not find a lobby with that name", "error")
    return
  end

  if not lobby.started then
    bridge.notify(playerId, "That lobby has not started yet", "error")
    return
  end

  if lobby.private then
    bridge.notify(playerId, "Private lobbies cannot be spectated from the public list", "error")
    return
  end

  state.addPlayer(lobby, playerId, true)

  local targetServerId <const> = state.resolveSpectateTarget(lobby, playerId)
  local payload <const> = state.getState(lobby, playerId, {
    started = true,
    tier = 1,
    spectator = true,
    targetServerId = targetServerId,
  })

  state.sendState(playerId, lobby, {
    started = true,
    tier = 1,
    spectator = true,
    targetServerId = targetServerId,
  })

  TriggerClientEvent("gungame:client:startMatch", playerId, payload)
  
  bridge.notify(playerId, ("You are spectating %s"):format(lobby.name), "info")
end)

RegisterNetEvent("gungame:server:leaveLobby", function()
  local playerId <const> = source
  if not (playerId and state.isOnline(playerId)) then return end

  if not state.playerLobby[playerId] then
    bridge.notify(playerId, "You are not in a lobby", "error")
    return
  end

  state.removePlayer(playerId, "You left the lobby")

  bridge.notify(playerId, "You left the lobby", "info")
end)

---@param lobbyName string
---@param password string?
RegisterNetEvent("gungame:server:changePassword", function(lobbyName, password)
  local playerId <const> = source
  if not (playerId and state.isOnline(playerId)) then return end

  local ownedLobbyName <const> = state.playerLobby[playerId]
  local lobby <const> = ownedLobbyName and state.lobbies[ownedLobbyName] or nil
  if not lobby or lobby.owner ~= playerId then
    bridge.notify(playerId, "You do not own a lobby", "error")
    return
  end

  if password == nil or password == "" then
    lobby.password = nil
    lobby.private = false
  else
    lobby.password = password
    lobby.private = true
  end

  bridge.notify(playerId, "Lobby password updated", "success")
  state.sendState(playerId, lobby, { started = lobby.started })
end)

RegisterNetEvent("gungame:server:deleteLobby", function()
  local playerId <const> = source
  if not (playerId and state.isOnline(playerId)) then return end

  local ownedLobbyName <const> = state.playerLobby[playerId]
  local lobby <const> = ownedLobbyName and state.lobbies[ownedLobbyName] or nil
  if not lobby or lobby.owner ~= playerId then
    bridge.notify(playerId, "You do not own a lobby", "error")
    return
  end

  state.clearLobby(ownedLobbyName, "The lobby was deleted")
  
  bridge.notify(playerId, "Lobby deleted", "success")
end)

---@return table<string, table>
lib.callback.register("gungame:server:getLobbies", function(source)
  local playerId <const> = source
  local response <const> = {}

  for lobbyName, lobby in pairs(state.lobbies) do
    response[lobbyName] = state.getLobby(lobby, playerId)
  end

  return response
end)

---@param lobbyName string
---@return table[]?
lib.callback.register("gungame:server:getLobbyMembers", function(source, lobbyName)
  local playerId <const> = source
  local lobby <const> = state.lobbies[lobbyName]
  if not lobby then
    return nil
  end

  if lobby.owner ~= playerId and state.playerLobby[playerId] ~= lobbyName then
    return nil
  end

  return state.getMembers(lobby)
end)

---@return table?
lib.callback.register("gungame:server:getOwnedLobby", function(source)
  local playerId <const> = source
  
  local lobbyName <const> = state.playerLobby[playerId]
  local lobby <const> = lobbyName and state.lobbies[lobbyName] or nil
  if not lobby or lobby.owner ~= playerId then
    return nil
  end

  return state.getLobby(lobby, playerId)
end)