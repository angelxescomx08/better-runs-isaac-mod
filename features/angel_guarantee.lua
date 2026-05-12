-- Guarantees an angel room on the next floor when a devil room door is skipped.
-- Carries the guarantee across floors until a deal room actually appears.

local save
local writeData

local run = {
    devilRoomExisted = false,
    enteredDevilRoom = false,
    bossRoomCleared  = false,
    dealCheckDone    = false,
}
local dealCheckFramesLeft = 0
local DEAL_CHECK_DELAY    = 5

local function resetFloorState()
    run.devilRoomExisted = false
    run.enteredDevilRoom = false
    run.bossRoomCleared  = false
    run.dealCheckDone    = false
    dealCheckFramesLeft  = 0
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

local function checkAndApplyGuarantee()
    local angelDesc = findRoomDescOfType(RoomType.ROOM_ANGEL)
    local devilDesc = findRoomDescOfType(RoomType.ROOM_DEVIL)

    run.devilRoomExisted = devilDesc ~= nil

    if not save.guaranteeAngel then return end

    if angelDesc then
        save.guaranteeAngel = false
        writeData()
    elseif devilDesc then
        -- NOTE: desc.Data.Type is writable in Repentance vanilla.
        -- If the door sprite does not update visually, REPENTOGON may be needed.
        devilDesc.Data.Type = RoomType.ROOM_ANGEL
        save.guaranteeAngel = false
        writeData()
        Isaac.DebugString("[BetterRuns] Devil room converted to angel (guarantee consumed).")
    end
    -- No deal room this floor (red heart damage): guarantee carries to next floor.
end

-- ── Callbacks ─────────────────────────────────────────────────────────────────

local function onGameStarted(_, isContinued)
    -- save is already loaded by main.lua before this callback fires
    if not isContinued then
        save.guaranteeAngel = false
        writeData()
    end
    resetFloorState()
end

local function onNewLevel()
    if run.devilRoomExisted and not run.enteredDevilRoom then
        save.guaranteeAngel = true
        writeData()
        Isaac.DebugString("[BetterRuns] Devil room skipped — angel guaranteed on next deal room.")
    end
    resetFloorState()
end

local function onNewRoom()
    if Game():GetRoom():GetType() == RoomType.ROOM_DEVIL then
        run.enteredDevilRoom = true
    end
end

local function onUpdate()
    local room = Game():GetRoom()

    if room:GetType() == RoomType.ROOM_BOSS and room:IsClear() and not run.bossRoomCleared then
        run.bossRoomCleared = true
        dealCheckFramesLeft = DEAL_CHECK_DELAY
    end

    if dealCheckFramesLeft > 0 then
        dealCheckFramesLeft = dealCheckFramesLeft - 1
        if dealCheckFramesLeft == 0 and not run.dealCheckDone then
            run.dealCheckDone = true
            checkAndApplyGuarantee()
        end
    end
end

local function onGameExit()
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
        mod:AddCallback(ModCallbacks.MC_POST_UPDATE,       onUpdate)
        mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT,     onGameExit)
        mod:AddCallback(ModCallbacks.MC_POST_GAME_END,     onGameEnd)
    end
}
