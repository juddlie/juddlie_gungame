local state <const> = require("client.state")

local bridge <const> = require("bridge")
local config <const> = require("config")

local function clearWeapons()
  RemoveAllPedWeapons(cache.ped, true)
  SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)
end

local function restorePed()
  FreezeEntityPosition(cache.ped, false)
  SetEntityVisible(cache.ped, true, false)
  SetEntityCollision(cache.ped, true, true)
  SetEntityInvincible(cache.ped, false)
  SetEntityAlpha(cache.ped, 255, false)
end

local function stopSpectating()
  if not state.spectating then return end

  state.spectating = false

  NetworkSetInSpectatorMode(false, cache.ped)
  restorePed()
end

---@param tier number
local function giveLoadout(tier)
  local weaponId <const> = state.weaponIndices[tier]
  if not weaponId then return end

  local weapon <const> = config.weapons[weaponId]
  if not weapon then return end

  clearWeapons()

  GiveWeaponToPed(cache.ped, weapon.hash, 250, false, true)
  SetCurrentPedWeapon(cache.ped, weapon.hash, true)
end

---@param targetServerId number
---@param spawn { x: number, y: number, z: number, heading?: number }
local function startSpectating(targetServerId, spawn)
  stopSpectating()

  local targetPlayer <const> = targetServerId and GetPlayerFromServerId(targetServerId) or -1
  if targetPlayer <= 0 then return end
  
  local targetPed <const> = GetPlayerPed(targetPlayer)
  if targetPed ~= 0 then
    state.spectating = true
    FreezeEntityPosition(cache.ped, true)
    SetEntityVisible(cache.ped, false, false)
    SetEntityCollision(cache.ped, false, false)
    SetEntityInvincible(cache.ped, true)
    NetworkSetInSpectatorMode(true, targetPed)
    return
  end

  if spawn then
    ---@diagnostic disable-next-line: param-type-mismatch
    NetworkResurrectLocalPlayer(spawn.x, spawn.y, spawn.z + 25.0, spawn.heading or 0.0, true, 0)
    SetEntityCoordsNoOffset(cache.ped, spawn.x, spawn.y, spawn.z + 25.0, false, false, false)
    SetEntityHeading(cache.ped, spawn.heading or 0.0)
  end

  state.spectating = true
  FreezeEntityPosition(cache.ped, true)
  SetEntityVisible(cache.ped, false, false)
  SetEntityCollision(cache.ped, false, false)
  SetEntityInvincible(cache.ped, true)
end

local function respawnPlayer()
  local spawn <const> = (state.lobby and state.lobby.spawn) or GetEntityCoords(cache.ped)
  local heading <const> = (state.lobby and state.lobby.spawn and state.lobby.spawn.heading)
    or GetEntityHeading(cache.ped)

  Wait(config.game.respawnDelay)

  ---@diagnostic disable-next-line: param-type-mismatch
  NetworkResurrectLocalPlayer(spawn.x, spawn.y, spawn.z, heading, true, 0)
  SetEntityCoordsNoOffset(cache.ped, spawn.x, spawn.y, spawn.z, false, false, false)
  SetEntityHeading(cache.ped, heading)
  ClearPedTasksImmediately(cache.ped)
  SetEntityHealth(cache.ped, GetEntityMaxHealth(cache.ped))
  SetPedArmour(cache.ped, config.game.respawnArmour or 0)

  state.reportedDeath = false

  if state.started and not state.spectating and not state.spectator then
    giveLoadout(state.tier)
  end
end

---@param attackerServerId? number
local function handleDeath(attackerServerId)
  if not (state.started and state.reportedDeath) then return end
  if state.spectating or state.spectator then return end

  state.reportedDeath = true

  if not (attackerServerId and attackerServerId > 0) then
    bridge.notify("You died", "error")
  end

  if attackerServerId ~= cache.serverId then
    TriggerServerEvent("gungame:server:reportKill", attackerServerId)
  end

  CreateThread(respawnPlayer)
end

RegisterNetEvent("gungame:client:updateLobbyState", function(data)
  state.setLobby(data)
end)

RegisterNetEvent("gungame:client:startMatch", function(data)
  state.setLobby(data)
  state.started = true
  state.reportedDeath = false

  local spawn <const> = data.spawn or {
    x = GetEntityCoords(cache.ped).x,
    y = GetEntityCoords(cache.ped).y,
    z = GetEntityCoords(cache.ped).z,
    heading = GetEntityHeading(cache.ped),
  }

  if state.spectator then
    startSpectating(data.targetServerId, spawn)
    return
  end

  stopSpectating()
  ---@diagnostic disable-next-line: param-type-mismatch
  NetworkResurrectLocalPlayer(spawn.x, spawn.y, spawn.z, spawn.heading or 0.0, true, 0)
  SetEntityCoordsNoOffset(cache.ped, spawn.x, spawn.y, spawn.z, false, false, false)
  SetEntityHeading(cache.ped, spawn.heading or 0.0)
  ClearPedTasksImmediately(cache.ped)
  SetEntityHealth(cache.ped, GetEntityMaxHealth(cache.ped))
  SetPedArmour(cache.ped, config.game.respawnArmour or 0)

  giveLoadout(state.tier)
end)

RegisterNetEvent("gungame:client:updateTier", function(data)
  if not (state.started and state.lobby) then return end
  if data.lobbyName ~= state.lobbyName then return end
  if state.spectator then return end

  state.tier = data.tier or state.tier
  giveLoadout(state.tier)
end)

RegisterNetEvent("gungame:client:matchEnded", function(data)
  if not state.lobbyName then return end
  if data.lobbyName ~= state.lobbyName then return end

  state.started = false
  state.reportedDeath = false
  state.tier = 1

  clearWeapons()
  stopSpectating()

  if data.winnerName then
    bridge.notify(("%s won the match"):format(data.winnerName), "success")
  end
end)

RegisterNetEvent("gungame:client:clearLobbyState", function(data)
  stopSpectating()
  state.reset()
  clearWeapons()
  restorePed()

  if data and data.message then
    bridge.notify(data.message, "info")
  end
end)

AddEventHandler("gameEventTriggered", function(eventName, args)
  if eventName ~= "CEventNetworkEntityDamage" or state.reportedDeath then
    return
  end

  if type(args) ~= "table" then return end

  local victim <const> = args[1]
  local attacker <const> = args[2]
  local fatal <const> = args[6]
  if victim ~= cache.ped or fatal ~= true then
    return
  end

  local attackerServerId = nil
  if attacker and attacker ~= 0 then
    local attackerPlayer <const> = NetworkGetPlayerIndexFromPed(attacker)
    if attackerPlayer ~= -1 then
      attackerServerId = GetPlayerServerId(attackerPlayer)
    end
  end

  handleDeath(attackerServerId)
end)