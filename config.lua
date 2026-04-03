local config = {}

---@type "esx" | "ox"
config.framework = "esx"

config.interaction = {
  ---@type "ped" | "location" | "command"
  type = "ped",
  command = "gungame",
  location = {
    coords = vec3(-181.4622, -1326.6766, 31.2217),
    radius = 5.0,
  },
  ped = {
    model = `s_m_y_blackops_01`,
    coords = vec4(-183.6433, -1326.1453, 31.2371, 76.9306),
    scenario = "WORLD_HUMAN_GUARD_STAND",
    freeze = true,
    invincible = true,
  },
}

config.game = {
  defaultMaxPlayers = 8,
  defaultKillsPerTier = 1,
  respawnDelay = 3500,
  respawnArmour = 0,
  allowSpectate = true,
}

config.rewards = {
  kill = {
    amount = 0,
    account = "money",
    item = nil,
  },
  win = {
    amount = 0,
    account = "money",
    item = nil,
  },
}

config.weapons = {
  { label = "Pistol", hash = `WEAPON_PISTOL` },
  { label = "Combat Pistol", hash = `WEAPON_COMBATPISTOL` },
  { label = "AP Pistol", hash = `WEAPON_APPISTOL` },
  { label = "Micro SMG", hash = `WEAPON_MICROSMG` },
  { label = "SMG", hash = `WEAPON_SMG` },
  { label = "Assault Rifle", hash = `WEAPON_ASSAULTRIFLE` },
  { label = "Carbine Rifle", hash = `WEAPON_CARBINERIFLE` },
  { label = "Pump Shotgun", hash = `WEAPON_PUMPSHOTGUN` },
  { label = "Heavy Sniper", hash = `WEAPON_HEAVYSNIPER` },
  { label = "Knife", hash = `WEAPON_KNIFE` },
}

return config