fx_version "cerulean"
game "gta5"
lua54 "yes"

author "juddlie"
description "A fully featured Gun Game script for FiveM with progressive weapon tiers, automatic leveling, and optimized performance. Easy to configure and integrate into any server."

shared_scripts {
  "@ox_lib/init.lua",
  "bridge/init.lua",
  "config.lua",
}

server_scripts {
  "server/state.lua",
  "server/lobbies.lua",
  "server/match.lua",
}

client_scripts {
  "client/state.lua",
  "client/menus.lua",
  "client/match.lua",
  "client/interaction.lua",
}

files {
  "bridge/**/client.lua",
}