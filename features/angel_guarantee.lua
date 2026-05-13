-- Guarantees an angel room on the next deal when the devil room is skipped.
-- The guarantee carries across floors until an angel deal actually appears.
--
-- Implementation notes
-- --------------------
-- 1. Deal-room observation runs on MC_POST_NEW_ROOM, not on a delayed timer
--    after boss-kill. The descriptor at GridRooms.ROOM_DEVIL_IDX is created
--    during floor generation, so we can poll it any time during the floor.
--    A delayed snapshot races with the player jumping into the trapdoor.
--
-- 2. To force an angel deal we must wipe any pre-rolled descriptor first,
--    otherwise Level:InitializeDevilAngelRoom is a documented no-op.
--    See: https://wofsauge.github.io/IsaacDocs/rep/Level.html#initializedevilangelroom
--
-- 3. We deliberately do NOT mutate RoomDescriptor.Data.Type on a live deal
--    room. That path was found to crash the game on Repentance+.

local save
local writeData

local run = {
    devilRoomExisted = false,
    enteredDevilRoom = false,
}

local function resetFloorState()
    run.devilRoomExisted = false
    run.enteredDevilRoom = false
end

local function findRoomDescOfType(roomType)
    local rooms = Game():GetLevel():GetRooms()
    for i = 0, rooms.Size - 1 do
        local desc = rooms:Get(i)
        if desc and desc.Data and desc.Data.Type == roomType then
            return desc
        end
    end
    return nil
end

local function tryForceAngelThisFloor()
    if not save.guaranteeAngel then return end

    local level    = Game():GetLevel()
    local dealRoom = level:GetRoomByIdx(GridRooms.ROOM_DEVIL_IDX)

    -- If the engine already locked the deal in (almost always the case during
    -- floor generation), InitializeDevilAngelRoom would no-op. Wipe the data
    -- so the re-initialization actually takes effect.
    if dealRoom and dealRoom.Data then
        dealRoom.Data = nil
    end

    level:InitializeDevilAngelRoom(true, false)
    Isaac.DebugString("[BetterRuns] Angel deal forced for this floor.")
end

-- ── Callbacks ─────────────────────────────────────────────────────────────────

local function onGameStarted(_, isContinued)
    if not isContinued then
        save.guaranteeAngel = false
        writeData()
    end
    resetFloorState()
    -- On continue, MC_POST_NEW_LEVEL won't fire, so apply the carried-over
    -- guarantee here too.
    tryForceAngelThisFloor()
end

local function onNewLevel()
    -- This check uses the previous floor's state because resetFloorState() and
    -- the new floor's MC_POST_NEW_ROOM scans haven't run yet.
    if run.devilRoomExisted and not run.enteredDevilRoom then
        save.guaranteeAngel = true
        writeData()
        Isaac.DebugString("[BetterRuns] Devil room skipped — angel guaranteed on next deal.")
    end

    resetFloorState()
    tryForceAngelThisFloor()
end

local function onNewRoom()
    local room = Game():GetRoom()
    if room:GetType() == RoomType.ROOM_DEVIL then
        run.enteredDevilRoom = true
    end

    -- Observe the deal slot continuously. We only ever flip the flag ON; we
    -- never clear it back to false within a floor, so the moment any devil
    -- descriptor exists this floor we remember it until resetFloorState().
    if findRoomDescOfType(RoomType.ROOM_DEVIL) then
        run.devilRoomExisted = true
    end

    -- If we were carrying a guarantee and an angel descriptor has materialized
    -- on this floor, the guarantee is fulfilled — clear it.
    if save.guaranteeAngel and findRoomDescOfType(RoomType.ROOM_ANGEL) then
        save.guaranteeAngel = false
        writeData()
        Isaac.DebugString("[BetterRuns] Angel deal observed (guarantee consumed).")
    end
end

local function onGameExit()
    -- Persist the carry-over before quitting in the middle of a floor.
    if run.devilRoomExisted and not run.enteredDevilRoom then
        save.guaranteeAngel = true
    end
    writeData()
end

local function onGameEnd()
    save.guaranteeAngel = false
    writeData()
    resetFloorState()
end

-- ── Public interface ──────────────────────────────────────────────────────────

return {
    init = function(mod, saveRef, writeFn)
        save      = saveRef
        writeData = writeFn
        mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, onGameStarted)
        mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL,    onNewLevel)
        mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM,     onNewRoom)
        mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT,     onGameExit)
        mod:AddCallback(ModCallbacks.MC_POST_GAME_END,     onGameEnd)
    end
}
