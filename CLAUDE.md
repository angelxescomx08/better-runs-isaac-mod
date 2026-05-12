# Better Runs — Mod para The Binding of Isaac: Repentance+

Mod de Lua para The Binding of Isaac: Repentance / Repentance+.  
Objetivo: mejorar la experiencia de runs (estadísticas, calidad de vida, mecánicas extra).

## Estructura del proyecto

```
better-runs/
├── CLAUDE.md
├── metadata.xml          # Requerido: nombre, directorio, descripción del mod
├── main.lua              # Punto de entrada; registra el mod y sus callbacks
├── resources/            # Assets personalizados (sprites, sonidos, fuentes)
│   ├── gfx/
│   └── sounds/
└── content/              # Overrides XML (ítems, entidades, salas)
```

## Archivos clave

### metadata.xml
Obligatorio para que el juego reconozca el mod y para subir al Steam Workshop.

```xml
<metadata>
  <name>Better Runs</name>
  <directory>better-runs</directory>
  <description>Mejoras de calidad de vida y estadísticas para tus runs.</description>
  <version>0.1.0</version>
  <visibility>Public</visibility>
</metadata>
```

Tras subir al Workshop por primera vez, el juego inserta automáticamente un campo `<id>`.

### main.lua — patrón base

```lua
local mod = RegisterMod("Better Runs", 1)
local json = require("json")  -- incluido en el juego

-- Estado persistente (se serializa a JSON)
local saveData = {
  totalRuns   = 0,
  wins        = 0,
  bestFloor   = 0,
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

-- Callbacks
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

### Callbacks más usados en mods de run

| Callback | Cuándo se dispara |
|---|---|
| `MC_POST_GAME_STARTED` | Al iniciar o continuar un run (`isContinued: bool`) |
| `MC_PRE_GAME_EXIT`     | Antes de salir del run (`shouldSave: bool`) |
| `MC_POST_GAME_END`     | Al terminar el run (`isVictory: bool`) |
| `MC_POST_NEW_LEVEL`    | Al llegar a un nuevo piso |
| `MC_POST_UPDATE`       | Cada frame de actualización del juego |
| `MC_POST_PLAYER_INIT`  | Al inicializar al jugador |
| `MC_POST_PICKUP_INIT`  | Al aparecer un pickup (ítem, moneda, etc.) |
| `MC_USE_ITEM`          | Al usar un ítem activo |
| `MC_POST_NPC_DEATH`    | Al morir un enemigo |

### Helpers globales útiles

```lua
local game    = Game()
local level   = game:GetLevel()
local room    = game:GetRoom()
local player  = Isaac.GetPlayer(0)

-- Info del piso actual
level:GetAbsoluteStage()    -- número de piso (1–13)
level:GetStageType()        -- tipo de piso (normal, alt path, etc.)

-- Info del jugador
player:GetMaxHearts()
player:GetNumCoins()
player:GetNumKeys()
player:GetNumBombs()
player:HasCollectible(CollectibleType.COLLECTIBLE_SAD_ONION)

-- Spawn de entidades
Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, 0, pos, vel, nil)

-- Log de debug (aparece en la consola del juego, actívala con ~ o en options.ini debug=1)
Isaac.DebugString("mensaje de debug")
```

### Persistencia de datos

```lua
Isaac.SaveModData(mod, json.encode(tabla))   -- guarda como string JSON
Isaac.LoadModData(mod)                        -- devuelve el string guardado
Isaac.HasModData(mod)                         -- true si hay datos guardados
Isaac.RemoveModData(mod)                      -- borra los datos guardados
```

Los datos se guardan en `The Binding of Isaac Rebirth/data/<nombre-mod>.dat`.

## Enums frecuentes

- `ModCallbacks.*` — todos los callbacks disponibles
- `EntityType.*` — tipos de entidad (ENTITY_PLAYER, ENTITY_NPC, ENTITY_PICKUP…)
- `CollectibleType.*` — ítems pasivos y activos
- `PickupVariant.*` — subtipos de pickups
- `LevelStage.*` — pisos del juego
- `PlayerType.*` — personajes (PLAYER_ISAAC, PLAYER_MAGDALENE…)
- `SoundEffect.*` — sonidos del juego

## Herramientas de desarrollo

- **VS Code + extensión "Binding of Isaac Lua API"** (Filloax) — autocompletado del API
- **IsaacScript** — alternativa en TypeScript transpilada a Lua con tipado estricto
- **Consola de debug del juego** — actívala con `debug=1` en `options.ini` y ábrela con `~`
- **REPENTOGON** — framework de extensión de la API con más hooks y funciones

## Documentación

- API oficial: https://wofsauge.github.io/IsaacDocs/rep/
- REPENTOGON API: https://repentogon.com/docs.html
- IsaacScript: https://isaacscript.github.io/
- Wiki de modding: https://bindingofisaacrebirth.fandom.com/wiki/Category:Lua_Reference

## Convenciones del proyecto

- Lua 5.3 (el juego incluye su propio runtime de Lua)
- Un solo `RegisterMod` en `main.lua`; dividir la lógica en archivos separados con `require`
- Todo el estado persistente va en una tabla única serializada a JSON
- Guardar (`save()`) en `MC_PRE_GAME_EXIT` y `MC_POST_NEW_LEVEL` como mínimo
- No usar variables globales sueltas; prefijarlas con el nombre del mod si es necesario
