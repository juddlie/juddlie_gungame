local config <const> = require("config")

local lobbies = {}
local lobbiesById = {}
local playersInLobby = {}

---@param data { maxPlayers: number, weapons: number[], lobbyName?: string, password?: string, isPrivate?: boolean }
RegisterNetEvent("gungame:server:createLobby", function(data)
  local source <const> = source
  if not source then return end

  if lobbies[source] then
    config.notify("You already have a active lobby!", "error", source)
    return
  end

  if playersInLobby[source] then
    config.notify("You are already in a lobby!", "error", source)
    return
  end

  local lobbyName <const> = data?.lobbyName or ("%s's Lobby"):format(GetPlayerName(source))

  lobbies[lobbyName] = {
    owner = source,
    maxPlayers = data.maxPlayers,
    weapons = data.weapons,
    lobbyName = lobbyName,
    password = data?.password,
    private = data?.isPrivate
  }

  lobbiesById[source] = lobbiesById
  playersInLobby[source] = lobbyName

  config.notify("You have successfully created a lobby!", "success", source)
end)

---@param lobbyName string
---@param password string?
RegisterNetEvent("gungame:server:joinLobby", function(lobbyName, password)
  local source <const> = source
  if not source then return end

  local lobby <const> = lobbies[lobbyName]
  if not lobby then
    config.notify("Could not find a lobby with that name", "error", source)
    return
  end

  if lobby.owner == source then
    config.notify("You cannot join a lobby you already own", "error", source)
    return
  end

  if lobby.password ~= password then
    config.notify("Incorrect lobby password", "error", source)
    return
  end

  playersInLobby[source] = lobbyName

  config.notify(("You have joined %s"):format(lobby.lobbyName), "success", source)
end)

---@return table?
lib.callback.register("gungame:server:getLobbies", function(source)
  local source <const> = source
  if not source then return end

  return lobbies
end)