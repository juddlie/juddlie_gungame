local config <const> = require("config")

local function openLobbiesMenu()
  local lobbies <const> = lib.callback.await("gungame:server:getLobbies", false)
  if table.type(lobbies) == "empty" then
    config.notify("There are no active lobbies", "error")
    return
  end

  local options = {}
  for lobbyName, lobby in pairs(lobbies) do
    local isOwner <const> = lobby.owner == cache.serverId
    
    options[#options + 1] = {
      label = lobbyName,
      icon = isOwner and "fa-crown" or "fa-user"
    }
  end

  lib.registerMenu({
    id = "gungame:lobbies:menu",
    title = "View Lobbies",
    position = "top-right",
    onClose = function(keyPressed)
      lib.showMenu("gungame:menu")
    end,
    options = options
  }, function()
    
  end)

  lib.showMenu("gungame:lobbies:menu")
end

do
  local formattedWeapons = {}
  for i = 0, #config.weapons do
    local weapon <const> = config.weapons[i]
    
    formattedWeapons[#formattedWeapons + 1] = {
      label = weapon.label,
      value = i
    }
  end
  
  lib.registerMenu({
    id = "gungame:menu",
    title = "Gun Game Menu",
    position = "top-right",
    options = {
      { label = "Create Lobby", icon = "fa-pencil" },
      { label = "Join Lobby", icon = "fa-user" },
      { label = "View Lobbies", icon = "fa-list" },
    }
  }, function(selected)
    if selected == 1 then
      local input = lib.inputDialog("Create Lobby", {
        { type = "number", label = "Max Players", required = true },
        { type = "multi-select", label = "Available Weapons", options = formattedWeapons, required = true },
        { type = "input", label = "Lobby Name" },
        { type = "input", label = "Password", password = true },
        { type = "checkbox", label = "Private Lobby", checked = false },
      })
      if not input then return end

      local data = {
        maxPlayers = input[1],
        weapons = input[2],
        lobbyName = input[3] ~= "" and input[3] or nil,
        password = input[4],
        isPrivate = input[5]
      }

      TriggerServerEvent("gungame:server:createLobby", data)
    elseif selected == 2 then
      local input = lib.inputDialog("Join Lobby", {
        { type = "input", label = "Lobby Name", required = true },
        { type = "input", label = "Password", password = true },
      })
      if not input then return end

      local lobbyName <const> = input[1]
      local password <const> = input[2]

      TriggerServerEvent("gungame:server:joinLobby", lobbyName, password)
    elseif selected == 3 then
      openLobbiesMenu()
    end
  end)
end

RegisterCommand("gungame", function(source, args, raw)
  lib.showMenu("gungame:menu")
end)