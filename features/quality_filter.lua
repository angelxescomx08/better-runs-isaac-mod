-- Prevents Tainted Lost from receiving items below a minimum quality tier.
--
-- Default minimum: quality 2 (tiers 0 and 1 are blocked).
-- If item 691 is held: minimum raises to quality 3 (tier 2 also blocked).
--
-- When a pedestal with a disqualified item spawns, we sample the same pool
-- for a qualifying replacement. If none is found the pedestal is left as-is.

local QUALITY_RAISER_ITEM = 691   -- holding this item raises the quality floor
local MIN_QUALITY_BASE    = 2     -- blocks tiers 0 and 1
local MIN_QUALITY_RAISED  = 3     -- blocks tiers 0, 1 and 2 when item 691 is held
local MAX_REROLL_ATTEMPTS = 100

-- Maps room types that can contain item pedestals to their item pool.
-- Room:GetItemPoolType() is not available in vanilla Repentance.
local ROOM_POOL = {
    [RoomType.ROOM_TREASURE]    = ItemPoolType.POOL_TREASURE,
    [RoomType.ROOM_SHOP]        = ItemPoolType.POOL_SHOP,
    [RoomType.ROOM_BOSS]        = ItemPoolType.POOL_BOSS,
    [RoomType.ROOM_DEVIL]       = ItemPoolType.POOL_DEVIL,
    [RoomType.ROOM_ANGEL]       = ItemPoolType.POOL_ANGEL,
    [RoomType.ROOM_SECRET]      = ItemPoolType.POOL_SECRET,
    [RoomType.ROOM_LIBRARY]     = ItemPoolType.POOL_LIBRARY,
    [RoomType.ROOM_CURSE]       = ItemPoolType.POOL_CURSE,
    [RoomType.ROOM_PLANETARIUM] = ItemPoolType.POOL_PLANETARIUM,
    [RoomType.ROOM_CHALLENGE]   = ItemPoolType.POOL_TREASURE,
}

local function findTaintedLost()
    for i = 0, Game():GetNumPlayers() - 1 do
        local p = Isaac.GetPlayer(i)
        if p:GetPlayerType() == PlayerType.PLAYER_THELOST_B then
            return p
        end
    end
    return nil
end

local function getMinQuality(player)
    if player:HasCollectible(QUALITY_RAISER_ITEM) then
        return MIN_QUALITY_RAISED
    end
    return MIN_QUALITY_BASE
end

local function findQualifyingItem(poolType, minQuality, baseSeed)
    local itemPool = Game():GetItemPool()
    local rng      = RNG()
    rng:SetSeed(baseSeed, 35)

    for _ = 1, MAX_REROLL_ATTEMPTS do
        local seed      = rng:Next()
        local candidate = itemPool:GetCollectible(poolType, false, seed)

        if candidate == CollectibleType.COLLECTIBLE_NULL then
            return nil, nil   -- pool exhausted
        end

        local cfg = Isaac.GetItemConfig():GetCollectible(candidate)
        if cfg and cfg.Quality >= minQuality then
            return candidate, seed
        end
    end

    return nil, nil
end

local function onPickupInit(_, pickup)
    if pickup.SubType == CollectibleType.COLLECTIBLE_NULL then return end

    local player = findTaintedLost()
    if not player then return end

    local itemCfg = Isaac.GetItemConfig():GetCollectible(pickup.SubType)
    if not itemCfg then return end

    local minQuality = getMinQuality(player)
    if itemCfg.Quality >= minQuality then return end

    -- Item is below the quality floor — find a replacement.
    local poolType = ROOM_POOL[Game():GetRoom():GetType()]
    if not poolType then return end   -- unknown room type; leave pedestal untouched

    local newItem, confirmSeed = findQualifyingItem(poolType, minQuality, pickup.InitSeed)
    if not newItem then
        -- Pool has no qualifying item; leave the pedestal as-is.
        Isaac.DebugString(("[BetterRuns] No quality %d+ item found in pool %d for Tainted Lost."):format(minQuality, poolType))
        return
    end

    -- Officially consume the replacement from the pool with decrease=true.
    Game():GetItemPool():GetCollectible(poolType, true, confirmSeed)
    pickup.SubType = newItem

    Isaac.DebugString(("[BetterRuns] Rerolled quality %d item → quality %d (item %d) for Tainted Lost."):format(
        itemCfg.Quality, Isaac.GetItemConfig():GetCollectible(newItem).Quality, newItem))
end

-- ── Public interface ──────────────────────────────────────────────────────────

return {
    init = function(mod)
        mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, onPickupInit, PickupVariant.PICKUP_COLLECTIBLE)
    end
}
