-- Reduces shop item prices to 15 coins when they would normally cost 30 or 99.
-- Covers Greed mode shops (where Sacred Heart, R Key, etc. cost 30 or 99)
-- and The Stairway (item 586) angel shops that use those same price points.

local TARGET_PRICE     = 15
local PRICES_TO_REDUCE = { [30] = true, [99] = true }

local function applyDiscount(entity)
    -- entity.Price is accessible on both EntityPickup and Entity from FindByType
    if entity.Price and PRICES_TO_REDUCE[entity.Price] then
        entity.Price = TARGET_PRICE
    end
end

-- Catch items at spawn time.
local function onPickupInit(_, pickup)
    if pickup.SubType == CollectibleType.COLLECTIBLE_NULL then return end
    applyDiscount(pickup)
end

-- Safety net: prices can be assigned after init in some contexts (e.g. Greed shops on re-entry).
local function onNewRoom()
    for _, ent in ipairs(Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, -1)) do
        applyDiscount(ent)
    end
end

-- ── Public interface ──────────────────────────────────────────────────────────

return {
    init = function(mod)
        mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, onPickupInit, PickupVariant.PICKUP_COLLECTIBLE)
        mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM,    onNewRoom)
    end
}
