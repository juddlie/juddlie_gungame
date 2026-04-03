local state <const> = {
  lobbyName = nil,
  lobby = nil,
  tier = 1,
  weaponIndices = {},
  started = false,
  spectator = false,
  spectating = false,
  reportedDeath = false,
}

---@param data table
function state.setLobby(data)
  state.lobbyName = data.lobbyName
  state.lobby = data
  state.weaponIndices = data.weaponIndices or {}
  state.tier = data.tier or 1
  state.started = data.started == true
  state.spectator = data.spectator == true
end

function state.reset()
  state.lobbyName = nil
  state.lobby = nil
  state.tier = 1
  state.weaponIndices = {}
  state.started = false
  state.spectator = false
  state.spectating = false
  state.reportedDeath = false
end

return state