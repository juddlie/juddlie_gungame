local state <const> = require("client.state")

local bridge <const> = require("bridge")
local config <const> = require("config")

local menus <const> = {}
local weaponOptions <const> = {}

---@param prefix string
---@param value string
---@return string
local function getMenuId(prefix, value)
  local sanitized <const> = tostring(value):gsub("[^%w]", "_")
  
  return ("%s:%s"):format(prefix, sanitized)
end

local function openCreateLobbyDialog()
  local input <const> = lib.inputDialog("Create Lobby", {
    { type = "input", label = "Lobby Name" },
    { type = "number", label = "Max Players", required = true, default = config.game.defaultMaxPlayers },
    { type = "number", label = "Kills per Weapon Tier", required = true, default = config.game.defaultKillsPerTier },
    { type = "multi-select", label = "Available Weapons", options = weaponOptions, required = true },
    { type = "input", label = "Password", password = true },
    { type = "checkbox", label = "Private Lobby", checked = false },
  })
  if not input then return end

  TriggerServerEvent("gungame:server:createLobby", {
    maxPlayers = input[2],
    killsPerTier = input[3],
    weapons = input[4],
    lobbyName = input[1] ~= "" and input[1] or nil,
    password = input[5],
    isPrivate = input[6] == true,
  })
end

local function openJoinLobbyDialog()
  local input <const> = lib.inputDialog("Join Lobby", {
    { type = "input", label = "Lobby Name", required = true },
    { type = "input", label = "Password", password = true },
  })
  if not input then return end

  TriggerServerEvent("gungame:server:joinLobby", input[1], input[2])
end

---@param lobbyName string
function menus.openMembersMenu(lobbyName)
  local members <const> = lib.callback.await("gungame:server:getLobbyMembers", false, lobbyName) or {}
  if #members == 0 then
    bridge.notify("There are no members in this lobby", "error")
    return
  end

  local options <const> = {}
  for _, member in ipairs(members) do
    options[#options + 1] = {
      label = member.name,
      description = member.isOwner and "Owner" or (member.spectator and "Spectating" or "Playing"),
      icon = member.isOwner and "fa-crown" or (member.spectator and "fa-eye" or "fa-user"),
    }
  end

  local menuId <const> = getMenuId("gungame:members", lobbyName)

  lib.registerMenu({
    id = menuId,
    title = "View Members",
    position = "top-right",
    onClose = function()
      if state.lobby then
        menus.openManageMenu(state.lobby)
      else
        menus.openMainMenu()
      end
    end,
    options = options,
  })

  lib.showMenu(menuId)
end

---@param lobby table?
function menus.openManageMenu(lobby)
  local ownedLobby <const> = lobby or lib.callback.await("gungame:server:getOwnedLobby", false)
  if not ownedLobby or not ownedLobby.isOwner then
    bridge.notify("You do not own that lobby", "error")
    return
  end

  local options <const> = {}
  if not ownedLobby.started then
    options[#options + 1] = { label = "Start Game", icon = "fa-play" }
  end

  options[#options + 1] = { label = "View Members", icon = "fa-users" }
  options[#options + 1] = { label = "Change Password", icon = "fa-key" }
  options[#options + 1] = { label = "Delete Lobby", icon = "fa-trash" }

  local menuId <const> = getMenuId("gungame:manage", ownedLobby.name)
  
  lib.registerMenu({
    id = menuId,
    title = ("Manage %s"):format(ownedLobby.name),
    position = "top-right",
    onClose = function()
      menus.openLobbiesMenu()
    end,
    options = options,
  }, function(selected)
    local choice <const> = options[selected]
    if not choice then return end

    if choice.label == "Start Game" then
      TriggerServerEvent("gungame:server:startLobby")
    elseif choice.label == "View Members" then
      menus.openMembersMenu(ownedLobby.name)
    elseif choice.label == "Change Password" then
      local input <const> = lib.inputDialog("Change Password", {
        { type = "input", label = "New Password", password = true },
      })
      if not input then return end

      TriggerServerEvent("gungame:server:changePassword", ownedLobby.name, input[1])
    elseif choice.label == "Delete Lobby" then
      local input <const> = lib.inputDialog("Delete Lobby", {
        { type = "checkbox", label = "I understand this will delete the lobby", checked = false, required = true },
      })
      if not (input and input[1]) then return end

      TriggerServerEvent("gungame:server:deleteLobby")
    end
  end)

  lib.showMenu(menuId)
end

---@param lobby table
function menus.openLobbyActionsMenu(lobby)
  local targetLobby <const> = lobby or {}
  local inAnotherLobby <const> = state.lobbyName ~= nil and state.lobbyName ~= targetLobby.name

  local options <const> = {}
  if targetLobby.isMember and not targetLobby.isOwner then
    options[#options + 1] = { label = "Leave Lobby", icon = "fa-right-from-bracket" }
  elseif not inAnotherLobby and not targetLobby.started then
    options[#options + 1] = { label = "Join Lobby", icon = "fa-user-plus" }
  end

  if config.game.allowSpectate and targetLobby.started and not inAnotherLobby and not targetLobby.private then
    options[#options + 1] = { label = "Spectate Lobby", icon = "fa-eye" }
  end

  if #options == 0 then
    bridge.notify("There are no available actions for that lobby", "error")
    return
  end

  local menuId <const> = getMenuId("gungame:lobby", targetLobby.name)

  lib.registerMenu({
    id = menuId,
    title = targetLobby.name,
    position = "top-right",
    onClose = function()
      menus.openLobbiesMenu()
    end,
    options = options,
  }, function(selected)
    local choice <const> = options[selected]
    if not choice then return end

    if choice.label == "Join Lobby" then
      if targetLobby.private then
        local input <const> = lib.inputDialog("Join Lobby", {
          { type = "input", label = "Password", password = true },
        })
        if not input then return end

        TriggerServerEvent("gungame:server:joinLobby", targetLobby.name, input[1])
        return
      end

      TriggerServerEvent("gungame:server:joinLobby", targetLobby.name, nil)
    elseif choice.label == "Spectate Lobby" then
      TriggerServerEvent("gungame:server:spectateLobby", targetLobby.name)
    elseif choice.label == "Leave Lobby" then
      TriggerServerEvent("gungame:server:leaveLobby")
    end
  end)

  lib.showMenu(menuId)
end

function menus.openMainMenu()
  lib.registerMenu({
    id = "gungame:menu",
    title = "Gun Game Menu",
    position = "top-right",
    options = {
      { label = "Create Lobby", icon = "fa-pencil" },
      { label = "Join Lobby", icon = "fa-user" },
      { label = "View Lobbies", icon = "fa-list" },
    },
  }, function(selected)
    if selected == 1 then
      openCreateLobbyDialog()
    elseif selected == 2 then
      openJoinLobbyDialog()
    elseif selected == 3 then
      menus.openLobbiesMenu()
    end
  end)

  lib.showMenu("gungame:menu")
end

function menus.openLobbiesMenu()
  local lobbies <const> = lib.callback.await("gungame:server:getLobbies", false) or {}
  if next(lobbies) == nil then
    bridge.notify("There are no active lobbies", "error")
    return
  end

  local entries <const> = {}
  for _, lobby in pairs(lobbies) do
    entries[#entries + 1] = lobby
  end

  table.sort(entries, function(left, right)
    return left.name < right.name
  end)

  local options <const> = {}
  for _, lobby in ipairs(entries) do
    local status <const> = lobby.started and "In progress" or "Waiting"
    local privacy <const> = lobby.private and "Private" or "Public"
    local spectatorText <const> = lobby.spectatorCount > 0 and (" | %d spectators"):format(lobby.spectatorCount) or ""

    options[#options + 1] = {
      label = lobby.name,
      description = ("%s | %d/%d active | %s | %s%s"):format(lobby.ownerName, lobby.memberCount, lobby.maxPlayers, privacy, status, spectatorText),
      icon = lobby.isOwner and "fa-crown" or (lobby.started and "fa-eye" or "fa-user"),
      args = lobby,
    }
  end

  lib.registerMenu({
    id = "gungame:lobbies:menu",
    title = "View Lobbies",
    position = "top-right",
    onClose = function()
      menus.openMainMenu()
    end,
    options = options,
  }, function(selected, _, args)
    if not args then return end

    if args.isOwner then
      menus.openManageMenu(args)
      return
    end

    menus.openLobbyActionsMenu(args)
  end)

  lib.showMenu("gungame:lobbies:menu")
end

do
  for index, weapon in ipairs(config.weapons) do
    weaponOptions[#weaponOptions + 1] = {
      label = weapon.label,
      value = index,
    }
  end
end

return menus