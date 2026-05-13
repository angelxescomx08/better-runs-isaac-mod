-- Guarantees an angel room on the next deal when the devil room is skipped.
-- Carries the guarantee across floors until a deal room actually appears.
--
-- We use Level:InitializeDevilAngelRoom(true, false) to lock the deal choice
-- to an angel room *before* the door is created. Mutating RoomDescriptor.Data.Type
-- on an already initialized deal room is unsupported and can crash the game on
-- Repentance / Repentance+ when the room descriptor desyncs from the layout.

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

local function tryForceAngelThisFloor()
    if not save.guaranteeAngel then return end
    -- Locks the deal choice to angel for the current floor. Calling it again
    -- once the deal is already initialized is a documented no-op, so it's safe
    -- to invoke on every new level / continue.
    Game():GetLevel():InitializeDevilAngelRoom(true, false)
    Isaac.DebugString("[BetterRuns] Angel deal forced for this floor.")
end

local function checkDealOutcome()
    local angelDesc = findRoomDescOfType(RoomType.ROOM_ANGEL)
    local devilDesc = findRoomDescOfType(RoomType.ROOM_DEVIL)

    run.devilRoomExisted = devilDesc ~= nil

    if not save.guaranteeAngel then return end

    if angelDesc then
        save.guaranteeAngel = false
        writeData()
        Isaac.DebugString("[BetterRuns] Angel room granted (guarantee consumed).")
    end
    -- No deal this floor (red heart damage, etc.): guarantee carries forward.
    -- If a devil descriptor slipped through (e.g. guarantee set after the deal
    -- was already locked in), leave the flag active so the next floor retries.
end

-- ── Callbacks ─────────────────────────────────────────────────────────────────

local function onGameStarted(_, isContinued)
    -- save is already loaded by main.lua before this callback fires
    if not isContinued then
        save.guaranteeAngel = false
        writeData()
    end
    resetFloorState()
    -- On continue, MC_POST_NEW_LEVEL may not fire, so apply the guarantee here too.
    tryForceAngelThisFloor()
end

local function onNewLevel()
    if run.devilRoomExisted and not run.enteredDevilRoom then
        save.guaranteeAngel = true
        writeData()
        Isaac.DebugString("[BetterRuns] Devil room skipped — angel guaranteed on next deal room.")
    end
    resetFloorState()
    tryForceAngelThisFloor()
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
            checkDealOutcome()
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
