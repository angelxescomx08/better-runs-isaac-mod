-- Increases item availability in Secret-style rooms without shipping any .stb,
-- so vanilla room generation stays intact.
--
-- 1. Secret Rooms (RoomType.ROOM_SECRET):
--      Pedestal rate is bumped from vanilla ~21% to TARGET_PROBABILITY via a
--      conditional spawn when the layout did not already include a pedestal.
--      Item comes from POOL_SECRET.
--
-- 2. Super Secret Rooms (RoomType.ROOM_SUPERSECRET):
--      When the variant uses a Sheol (Devil-themed) or Cathedral (Angel-themed)
--      backdrop, an item from the matching pool (POOL_DEVIL / POOL_ANGEL) is
--      always spawned. Heart / trinket / fortune / card themed variants are
--      left untouched.
--
-- All spawns are deterministic per room thanks to AwardSeed, so they survive
-- save+continue and reroll consistently.

local TARGET_PROBABILITY  = 1.00
local VANILLA_PROBABILITY = 0.21
local CONDITIONAL_SPAWN_PROB =
    (TARGET_PROBABILITY - VANILLA_PROBABILITY) / (1 - VANILLA_PROBABILITY)

-- Visual backdrop → pool to use for the bonus pedestal.
-- Super Secret Rooms always paint themselves with the backdrop of the theme
-- they impersonate, which is much more reliable than trying to map subtypes.
local SUPER_SECRET_POOL_BY_BACKDROP = {
    [BackdropType.SHEOL]     = ItemPoolType.POOL_DEVIL,
    [BackdropType.CATHEDRAL] = ItemPoolType.POOL_ANGEL,
}

local function roomHasCollectible()
    local pedestals = Isaac.FindByType(
        EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, -1, false, false)
    return #pedestals > 0
end

local function spawnPedestalFromPool(room, poolType, rng)
    local item = Game():GetItemPool():GetCollectible(poolType, true, rng:Next())
    if item == CollectibleType.COLLECTIBLE_NULL then return nil end

    local pos = Isaac.GetFreeNearPosition(room:GetCenterPos(), 40)
    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE,
        item, pos, Vector(0, 0), nil)
    return item
end

local function handleSecretRoom(room)
    if roomHasCollectible() then return end

    local rng = RNG()
    rng:SetSeed(room:GetAwardSeed(), 35)
    if rng:RandomFloat() >= CONDITIONAL_SPAWN_PROB then return end

    local item = spawnPedestalFromPool(room, ItemPoolType.POOL_SECRET, rng)
    if item then
        Isaac.DebugString(("[BetterRuns] Secret room pedestal spawned (item %d)."):format(item))
    end
end

local function handleSuperSecretRoom(room)
    local pool = SUPER_SECRET_POOL_BY_BACKDROP[room:GetBackdropType()]
    if not pool then return end                -- not a devil/angel-themed variant
    if roomHasCollectible() then return end    -- already has one, don't double up

    local rng = RNG()
    rng:SetSeed(room:GetAwardSeed(), 35)

    local item = spawnPedestalFromPool(room, pool, rng)
    if item then
        local theme = (pool == ItemPoolType.POOL_DEVIL) and "devil" or "angel"
        Isaac.DebugString(("[BetterRuns] Super-secret %s pedestal spawned (item %d)."):format(theme, item))
    end
end

local function onNewRoom()
    local room = Game():GetRoom()
    if not room:IsFirstVisit() then return end

    local rt = room:GetType()
    if rt == RoomType.ROOM_SECRET then
        handleSecretRoom(room)
    elseif rt == RoomType.ROOM_SUPERSECRET then
        handleSuperSecretRoom(room)
    end
end

-- ── Public interface ──────────────────────────────────────────────────────────

return {
    init = function(mod)
        mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, onNewRoom)
    end
}
