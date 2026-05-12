# Better Runs — Mod para The Binding of Isaac: Repentance+

Mod de Lua para The Binding of Isaac: Repentance / Repentance+.  
Objetivo: mejorar la experiencia de runs (estadísticas, calidad de vida, mecánicas extra).

## Estructura del proyecto

```
better-runs/
├── CLAUDE.md
├── README.md
├── metadata.xml          # Required: mod name, directory, description
├── main.lua              # Entry point; registers the mod and its callbacks
├── resources/            # Custom assets (sprites, sounds, fonts)
│   ├── gfx/
│   └── sounds/
└── content/              # XML overrides (items, entities, rooms)
```

## Archivos clave

### metadata.xml
Obligatorio para que el juego reconozca el mod y para subir al Steam Workshop.

```xml
<metadata>
  <name>Better Runs</name>
  <directory>better-runs</directory>
  <description>Quality of life improvements and run statistics.</description>
  <version>0.1.0</version>
  <visibility>Public</visibility>
</metadata>
```

After uploading to the Workshop for the first time, the game automatically inserts an `<id>` field.

### main.lua — base pattern

```lua
local mod = RegisterMod("Better Runs", 1)
local json = require("json")  -- bundled with the game

-- Persistent state (serialized to JSON)
local saveData = {
  totalRuns = 0,
  wins      = 0,
  bestFloor = 0,
}

local function save()
  Isaac.SaveModData(mod, json.encode(saveData))
end

local function load()
  if Isaac.HasModData(mod) then
    local raw = Isaac.LoadModData(mod)
    local ok, data = pcall(json.decode, raw)
    if ok then saveData = data end
  end
end

mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, isContinued)
  load()
  if not isContinued then
    saveData.totalRuns = saveData.totalRuns + 1
  end
  save()
end)

mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, function(_, shouldSave)
  save()
end)

mod:AddCallback(ModCallbacks.MC_POST_GAME_END, function(_, isVictory)
  if isVictory then
    saveData.wins = saveData.wins + 1
  end
  save()
end)
```

## API de Repentance — referencia rápida

### Most useful callbacks for run mods

| Callback | When it fires |
|---|---|
| `MC_POST_GAME_STARTED` | Run started or continued (`isContinued: bool`) |
| `MC_PRE_GAME_EXIT`     | Before exiting the run (`shouldSave: bool`) |
| `MC_POST_GAME_END`     | Run finished (`isVictory: bool`) |
| `MC_POST_NEW_LEVEL`    | Player reached a new floor |
| `MC_POST_UPDATE`       | Every game update frame |
| `MC_POST_PLAYER_INIT`  | Player entity initialized |
| `MC_POST_PICKUP_INIT`  | A pickup spawned (item, coin, etc.) |
| `MC_USE_ITEM`          | Active item used |
| `MC_POST_NPC_DEATH`    | An enemy died |

### Useful global helpers

```lua
local game   = Game()
local level  = game:GetLevel()
local room   = game:GetRoom()
local player = Isaac.GetPlayer(0)

-- Current floor info
level:GetAbsoluteStage()    -- floor number (1-13)
level:GetStageType()        -- stage type (normal, alt path, etc.)

-- Player info
player:GetMaxHearts()
player:GetNumCoins()
player:GetNumKeys()
player:GetNumBombs()
player:HasCollectible(CollectibleType.COLLECTIBLE_SAD_ONION)

-- Spawn entities
Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, 0, pos, vel, nil)

-- Debug log (enable with debug=1 in options.ini, open with ~)
Isaac.DebugString("debug message")
```

### Data persistence

```lua
Isaac.SaveModData(mod, json.encode(table))  -- save as JSON string
Isaac.LoadModData(mod)                       -- returns the saved string
Isaac.HasModData(mod)                        -- true if data exists
Isaac.RemoveModData(mod)                     -- deletes saved data
```

Data is stored in `The Binding of Isaac Rebirth/data/<mod-name>.dat`.

## Common enums

- `ModCallbacks.*` — all available callbacks
- `EntityType.*` — entity types (ENTITY_PLAYER, ENTITY_NPC, ENTITY_PICKUP…)
- `CollectibleType.*` — passive and active items
- `PickupVariant.*` — pickup subtypes
- `LevelStage.*` — game floors
- `PlayerType.*` — characters (PLAYER_ISAAC, PLAYER_MAGDALENE…)
- `SoundEffect.*` — game sounds

## Dev tools

- **VS Code + "Binding of Isaac Lua API" extension** (Filloax) — API autocomplete
- **IsaacScript** — TypeScript-to-Lua alternative with strict types
- **In-game debug console** — enable with `debug=1` in `options.ini`, open with `~`
- **REPENTOGON** — API extension framework with extra hooks and functions

## Docs

- Official API: https://wofsauge.github.io/IsaacDocs/rep/
- REPENTOGON API: https://repentogon.com/docs.html
- IsaacScript: https://isaacscript.github.io/
- Modding wiki: https://bindingofisaacrebirth.fandom.com/wiki/Category:Lua_Reference

## Project conventions

- Lua 5.3 (the game ships its own Lua runtime)
- Single `RegisterMod` call in `main.lua`; split logic into separate files with `require`
- All persistent state lives in one table serialized to JSON
- Always call `save()` in `MC_PRE_GAME_EXIT` and `MC_POST_NEW_LEVEL` at minimum
- Avoid loose globals; prefix with the mod name if unavoidable
- Code, comments, variable names, and commit messages in English
