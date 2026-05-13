-- Increases the effective probability that a secret room contains a collectible.
--
-- Vanilla secret rooms have an item pedestal in roughly 21% of variants. When a
-- secret room is entered for the first time and does NOT already contain one,
-- we spawn a pool-based collectible with conditional probability:
--
--     P(spawn | no pedestal) = (TARGET - VANILLA) / (1 - VANILLA) ≈ 0.367
--
-- which brings the overall observed rate to ~50%.
--
-- We deliberately do NOT ship a custom .stb file: in Repentance/Repentance+ a
-- mod's resources/rooms/<name>.stb replaces the vanilla file outright, which
-- would wipe Treasure / Shop / Devil / Angel / etc. variants and softlock level
-- generation. Spawning at runtime keeps every vanilla layout intact.

local TARGET_PROBABILITY  = 1.00
local VANILLA_PROBABILITY = 0.21
local CONDITIONAL_SPAWN_PROB =
    (TARGET_PROBABILITY - VANILLA_PROBABILITY) / (1 - VANILLA_PROBABILITY)

local function roomHasCollectible()
    -- Variant filter ensures we only look at pedestals, not cards, hearts, etc.
    local pedestals = Isaac.FindByType(
        EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, -1, false, false)
    return #pedestals > 0
end

local function onNewRoom()
    local game = Game()
    local room = game:GetRoom()

    if room:GetType() ~= RoomType.ROOM_SECRET then return end
    if not room:IsFirstVisit() then return end
    if roomHasCollectible() then return end

    -- AwardSeed is deterministic per-room, so rerolls/save+continue stay consistent.
    local rng = RNG()
    rng:SetSeed(room:GetAwardSeed(), 35)

    if rng:RandomFloat() >= CONDITIONAL_SPAWN_PROB then return end

    local pickSeed = rng:Next()
    local item = game:GetItemPool():GetCollectible(ItemPoolType.POOL_SECRET, true, pickSeed)
    if item == CollectibleType.COLLECTIBLE_NULL then return end

    local pos = Isaac.GetFreeNearPosition(room:GetCenterPos(), 40)
    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE,
        item, pos, Vector(0, 0), nil)

    Isaac.DebugString(("[BetterRuns] Spawned bonus secret-room pedestal (item %d)."):format(item))
end

-- ── Public interface ──────────────────────────────────────────────────────────

return {
    init = function(mod)
        mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, onNewRoom)
    end
}
