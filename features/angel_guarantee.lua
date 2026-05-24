-- On floor 3 (Caves I / Catacombs I / Mines I), if the player has never entered
-- a devil room in the run, gives them the Eucharist item (ID 499) so the angel
-- room chance becomes 100 % — exactly as if they had picked it up naturally.
--
-- The item is removed when:
--   · The player takes red heart damage on floor 3 (STATE_REDHEART_DAMAGED).
--   · The player leaves floor 3 (any subsequent floor).
--   · The run ends.
--
-- If the player already owns Eucharist naturally we skip giving it and never
-- touch their copy.  save.eucharistGiven persists across save/quit so the
-- tracking survives a continue.

local save
local writeData

local STAGE_FLOOR_3 = 3
local EUCHARIST     = CollectibleType.COLLECTIBLE_EUCHARIST  -- 499

local run = {
    gaveEucharist = false,
}

local function player0()
    return Isaac.GetPlayer(0)
end

local function give()
    local p = player0()
    if p:HasCollectible(EUCHARIST) then return end  -- already owns it naturally
    p:AddCollectible(EUCHARIST, 0, false)
    run.gaveEucharist  = true
    save.eucharistGiven = true
    writeData()
    Isaac.DebugString("[BetterRuns] Eucharist given — floor 3 angel guarantee active.")
end

local function remove()
    if not run.gaveEucharist then return end
    player0():RemoveCollectible(EUCHARIST)
    run.gaveEucharist  = false
    save.eucharistGiven = false
    writeData()
    Isaac.DebugString("[BetterRuns] Eucharist removed.")
end

-- ── Callbacks ─────────────────────────────────────────────────────────────────

local function onGameStarted(_, isContinued)
    if not isContinued then
        save.satanRejectedRun = true
        save.eucharistGiven   = false
        run.gaveEucharist     = false
        writeData()
    else
        -- Restore in-memory flag if we gave the item before the player saved.
        run.gaveEucharist = save.eucharistGiven == true
    end
end

local function onNewLevel()
    local stage = Game():GetLevel():GetAbsoluteStage()

    if stage ~= STAGE_FLOOR_3 then
        remove()   -- leaving floor 3 (or never on it) — clean up if needed
        return
    end

    -- Floor 3: give Eucharist if Satan was rejected
    if save.satanRejectedRun then
        give()
    end
end

-- Remove Eucharist the moment red heart damage is taken (checked every frame
-- while we hold the item, so the stat drops back immediately).
local function onUpdate()
    if not run.gaveEucharist then return end
    if Game():GetLevel():GetStateFlag(LevelStateFlag.STATE_REDHEART_DAMAGED) then
        remove()
    end
end

local function onNewRoom()
    local room = Game():GetRoom()
    if room:GetType() == RoomType.ROOM_DEVIL and save.satanRejectedRun then
        save.satanRejectedRun = false
        writeData()
        Isaac.DebugString("[BetterRuns] Devil room entered — Satan rejection broken.")
    end
end

local function onGameExit()
    -- Don't remove the item — player may continue the run.
    -- Just make sure the persistent flag reflects reality.
    writeData()
end

local function onGameEnd()
    remove()
    save.satanRejectedRun = true
    save.eucharistGiven   = false
    writeData()
end

-- ── Public interface ──────────────────────────────────────────────────────────

return {
    init = function(mod, saveRef, writeFn)
        save      = saveRef
        writeData = writeFn
        mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, onGameStarted)
        mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL,    onNewLevel)
        mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM,     onNewRoom)
        mod:AddCallback(ModCallbacks.MC_POST_UPDATE,       onUpdate)
        mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT,     onGameExit)
        mod:AddCallback(ModCallbacks.MC_POST_GAME_END,     onGameEnd)
    end
}
