# Juddlie Gun Game

A fully featured Gun Game resource for FiveM with progressive weapon tiers, lobby management, automatic leveling, and a split codebase that is easy to adapt for open-source use.

## Features

- Configurable interaction mode: command, location, or ped.
- Main menu flow with Create Lobby, Join Lobby, and View Lobbies.
- Create lobbies with:
  - Lobby name
  - Max players
  - Kills per weapon tier
  - Weapon tier selection
  - Private lobby password
- Joinable public lobbies and password-protected private lobbies.
- Spectate support for active public lobbies.
- Owner manage menu with:
  - Start Game
  - View Members
  - Change Password
  - Delete Lobby
- Progressive weapon tiers with automatic advancement after kills.
- Framework bridge hooks for kill and win payouts.

## Configuration

Most behavior is driven from [config.lua](config.lua)

- `config.interaction.type` controls how players open the menu.
- `config.interaction.command` sets the command name when command mode is enabled.
- `config.game.defaultMaxPlayers` and `config.game.defaultKillsPerTier` control lobby defaults.
- `config.game.allowSpectate` enables or disables spectating.
- `config.weapons` defines the weapon tier order.
- `config.rewards.kill` and `config.rewards.win` are data tables passed into the framework reward hooks.

Framework-specific logic lives in:

- [bridge/esx/server.lua](bridge/esx/server.lua)
- [bridge/esx/client.lua](bridge/esx/client.lua)
- [bridge/ox/server.lua](bridge/ox/server.lua)
- [bridge/ox/client.lua](bridge/ox/client.lua)

## Resource Requirements

- `ox_lib`
- Your selected framework bridge via `config.framework`
