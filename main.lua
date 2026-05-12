local mod  = RegisterMod("Better Runs", 1)
local json = require("json")

-- ── Shared persistent state ───────────────────────────────────────────────────
-- Features receive a reference to this table and modify keys in-place.
-- Never reassign `save = { ... }` after init — modules would lose the reference.

local save = {
    guaranteeAngel = false,
}

local function writeData()
    Isaac.SaveModData(mod, json.encode(save))
end

local function readData()
    if Isaac.HasModData(mod) then
        local ok, data = pcall(json.decode, Isaac.LoadModData(mod))
        if ok and type(data) == "table" then
            for k, v in pairs(data) do save[k] = v end
        end
    end
end

-- readData must fire before any feature callback on game start, so register it first.
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, _isContinued)
    readData()
end)

-- ── Features ──────────────────────────────────────────────────────────────────
-- Each module registers its own callbacks inside init().
-- Callbacks added here fire after readData() because they are registered later.

require("features.angel_guarantee").init(mod, save, writeData)
require("features.quality_filter").init(mod)
