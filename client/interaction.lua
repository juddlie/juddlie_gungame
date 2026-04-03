local menus <const> = require("client.menus")

local config <const> = require("config")

local interactionPed

---@param data { coords: table }
local function createPoint(data)
    local point <const> = lib.points.new({
    coords = data.coords,
    distance = 5.0
  })

  function point:onExit()
    lib.hideTextUI()
  end

  function point:nearby()
    if self.currentDistance > 2.0 then return end

    lib.showTextUI("Press [E] to Open Gun Game Menu")

    if IsControlJustReleased(0, 38) then
      menus.openMainMenu()
    end
  end
end

AddEventHandler("onResourceStart", function(resource)
  if resource ~= cache.resource then return end

  local interaction <const> = config.interaction
  if interaction.type == "ped" then 
    local pedConfig <const> = interaction.ped
    lib.requestModel(pedConfig.model)

    local success <const> = lib.waitFor(function()
      return HasModelLoaded(pedConfig.model)
    end, nil, 5000)
    if not success then return end

    local coords <const> = pedConfig.coords
    interactionPed = CreatePed(4, pedConfig.model, coords.x, coords.y, coords.z - 1.0, coords.w, false, true)
    SetEntityAsMissionEntity(interactionPed, true, true)
    SetBlockingOfNonTemporaryEvents(interactionPed, true)

    if pedConfig.freeze ~= false then
      FreezeEntityPosition(interactionPed, true)
    end

    if pedConfig.invincible ~= false then
      SetEntityInvincible(interactionPed, true)
    end

    if pedConfig.scenario then
      TaskStartScenarioInPlace(interactionPed, pedConfig.scenario, 0, true)
    end

    SetModelAsNoLongerNeeded(pedConfig.model)
    createPoint({ coords = coords })
  elseif interaction.type == "location" then
    createPoint({ coords = interaction.location.coords })
  end
end)

AddEventHandler("onResourceStop", function(resource)
  if resource ~= cache.resource then return end

  lib.hideTextUI()

  if interactionPed ~= 0 and DoesEntityExist(interactionPed) then
    DeleteEntity(interactionPed)
  end
end)

if config.interaction.command and config.interaction.command ~= "" then
  RegisterCommand(config.interaction.command, function()
    menus.openMainMenu()
  end, false)
end