fx_version "cerulean"
game "gta5"
lua54 "yes"

author "juddlie"
description "A fully featured Gun Game script for FiveM with progressive weapon tiers, automatic leveling, and optimized performance. Easy to configure and integrate into any server."

shared_scripts {
  "@ox_lib/init.lua",
  "config.lua",
}

server_scripts {
  "bridge/init.lua",
  "server/lobbies.lua"
}

client_scripts {
  "client/menus.lua"
}