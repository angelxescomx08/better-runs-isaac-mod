local mod  = RegisterMod("Better Runs", 1)
local json = require("json")

-- ── Persistent data (survives between sessions) ───────────────────────────────

local save = {
    guaranteeAngel = false,  -- true when player skipped a devil room last floor
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

-- ── Per-floor state (not persisted) ──────────────────────────────────────────

local run = {
    devilRoomExisted = false,  -- a devil room door appeared this floor
    enteredDevilRoom = false,  -- player actually walked into the devil room
    bossRoomCleared  = false,  -- boss was defeated this floor
    dealCheckDone    = false,  -- angel/devil room check already ran this floor
}
local dealCheckFramesLeft = 0
local DEAL_CHECK_DELAY    = 5  -- frames to wait after boss death before reading the room list

local function resetFloorState()
    run.devilRoomExisted = false
    run.enteredDevilRoom = false
    run.bossRoomCleared  = false
    run.dealCheckDone    = false
    dealCheckFramesLeft  = 0
end

-- ── Room list helpers ─────────────────────────────────────────────────────────

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

-- ── Feature: guaranteed angel room after skipping devil ───────────────────────

local function checkAndApplyGuarantee()
    local angelDesc = findRoomDescOfType(RoomType.ROOM_ANGEL)
    local devilDesc = findRoomDescOfType(RoomType.ROOM_DEVIL)

    -- Record whether a devil door appeared this floor (used on next level transition)
    run.devilRoomExisted = devilDesc ~= nil

    if not save.guaranteeAngel then return end

    if angelDesc then
        -- Angel room appeared on its own; consume the guarantee
        save.guaranteeAngel = false
        writeData()

    elseif devilDesc then
        -- Devil room appeared: convert it to angel.
        -- NOTE: modifying desc.Data.Type directly works in Repentance vanilla.
        -- If the door graphic does not update, REPENTOGON may be required.
        devilDesc.Data.Type = RoomType.ROOM_ANGEL
        save.guaranteeAngel = false
        writeData()
        Isaac.DebugString("[BetterRuns] Devil room converted to angel room (guarantee consumed).")

    end
    -- No deal room at all (player took red heart damage this floor):
    -- guarantee carries forward to the next floor where a deal room can appear.
end

-- ── Callbacks ─────────────────────────────────────────────────────────────────

mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, isContinued)
    readData()
    if not isContinued then
        save.guaranteeAngel = false
        writeData()
    end
    resetFloorState()
end)

-- Floor transition: check whether devil room was skipped on the floor we just left.
mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function()
    if run.devilRoomExisted and not run.enteredDevilRoom then
        save.guaranteeAngel = true
        writeData()
        Isaac.DebugString("[BetterRuns] Devil room skipped — angel room guaranteed next deal room.")
    end
    resetFloorState()
end)

-- Track whether the player actually enters the devil room.
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
    if Game():GetRoom():GetType() == RoomType.ROOM_DEVIL then
        run.enteredDevilRoom = true
    end
end)

-- Every frame: detect boss kill and run the delayed deal-room check.
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
    local room = Game():GetRoom()

    -- Detect boss room clearing for the first time this floor
    if room:GetType() == RoomType.ROOM_BOSS
        and room:IsClear()
        and not run.bossRoomCleared then
        run.bossRoomCleared = true
        dealCheckFramesLeft = DEAL_CHECK_DELAY
    end

    -- Countdown: fire once after the delay so the game has placed the deal door
    if dealCheckFramesLeft > 0 then
        dealCheckFramesLeft = dealCheckFramesLeft - 1
        if dealCheckFramesLeft == 0 and not run.dealCheckDone then
            run.dealCheckDone = true
            checkAndApplyGuarantee()
        end
    end
end)

-- Player quit mid-run: preserve devil-skip state so it applies on continue.
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, function()
    if run.devilRoomExisted and not run.enteredDevilRoom then
        save.guaranteeAngel = true
    end
    writeData()
end)

-- Run ended (death or victory): clear guarantee, it does not carry to new runs.
mod:AddCallback(ModCallbacks.MC_POST_GAME_END, function()
    save.guaranteeAngel = false
    writeData()
end)
