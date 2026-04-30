local action = require('action')
local database = require('database')
local gps = require('gps')
local scanner = require('scanner')
local config = require('config')
local events = require('events')
local breedRound = 0
local parents = {nil,nil};
local lastParentSlot = nil
local emtySlot1 = {}
local emtySlot2 = {}
local target = nil
-- ===================== FUNCTIONS ======================


local function checkChild(slot, crop, firstRun)
     if crop.isCrop then

        if crop.name == 'air' then
            action.placeCropStick(2)

        elseif crop.name == 'emptyCrop' then
            action.placeCropStick()

        elseif scanner.isWeed(crop, 'working') then
            action.deweed()
            action.placeCropStick()

        elseif firstRun then
            return
        elseif crop.name == parents[1].name or crop.name == parents[2].name then
            if crop.name == parents[1].name and #emtySlot1 > 0 then
                action.transplant(gps.workingSlotToPos(slot), gps.workingSlotToPos(emtySlot1[1]))
                table.remove(emtySlot1, 1)
            elseif crop.name == parents[2].name and #emtySlot2 > 0 then
                action.transplant(gps.workingSlotToPos(slot), gps.workingSlotToPos(emtySlot2[1]))
                table.remove(emtySlot2, 1)
            elseif config.keepParents then
                action.transplant(gps.workingSlotToPos(slot), gps.storageSlotToPos(database.nextStorageSlot()))
                action.placeCropStick(2)
                database.addToStorage(crop)
            else
                action.deweed()
                action.placeCropStick()
            end
        else
            if target ~= nil and crop.name:lower() ~= target then
                action.deweed()
                action.placeCropStick()
                return
            end
            action.transplant(gps.workingSlotToPos(slot), gps.storageSlotToPos(database.nextStorageSlot()))
            action.placeCropStick(2)
            database.addToStorage(crop)
        end
    end
end


local function checkParent(slot, crop, firstRun)
    if crop.isCrop and crop.name ~= 'air' and crop.name ~= 'emptyCrop' then
        if scanner.isWeed(crop, 'working') then
            action.deweed()
            database.updateFarm(slot, {isCrop=true, name='emptyCrop'})
        end
        if firstRun then
            if parents[1] == nil then
                parents[1] = crop
            elseif parents[2] == nil then
                parents[2] = crop
            end
        end
        if slot in emtySlot1 then
            table.remove(emtySlot1, table.find(emtySlot1, slot))
        end
        if slot in emtySlot2 then
            table.remove(emtySlot2, table.find(emtySlot2, slot))
        end
    elseif crop.isCrop and (crop.name == 'air' or crop.name == 'emptyCrop') then
        if lastParentSlot == parents[2] then
            lastParentSlot = parents[1]
            table.insert(emtySlot1, slot)
        elseif lastParentSlot == parents[1] then
            lastParentSlot = parents[2]
            table.insert(emtySlot2, slot)
        end
    end
    if lastParentSlot == nil then
        lastParentSlot = parents[1]
    elseif lastParentSlot == parents[1] then
        lastParentSlot = parents[2]
    elseif lastParentSlot == parents[2] then
        lastParentSlot = parents[1]
    end
end

-- ====================== THE LOOP ======================

local function breedOnce(firstRun)
    for slot=1, config.workingFarmArea, 1 do

        -- Terminal Condition
        if breedRound > config.maxBreedRound then
            print('autoBreed: Max Breeding Round Reached!')
            return false
        end

        -- Terminal Condition
        if database.isStorageFull(config.storageFarmArea) then
            print('autoBreed: Storage Full!')
            return false
        end

        -- Terminal Condition
        if events.needExit() then
            print('autoBreed: Received Exit Command!')
            return false
        end

        os.sleep(0)

        -- Scan
        gps.go(gps.workingSlotToPos(slot))
        local crop = scanner.scan()

        if firstRun then
            database.updateFarm(slot, crop)
        end

        if slot % 2 == 0 then
            checkChild(slot, crop, firstRun)
        else
            checkParent(slot, crop, firstRun)
        end

        if action.needCharge() then
            action.charge()
        end
    end
    return true
end

-- ======================== MAIN ========================
local args = {...}
local function main()
    if #args > 0 then
        target = args[1]:lower()
        print('autoBreed: Target Crop - ' .. target)
    end
    action.initWork()
    print('autoBreed: Scanning Farm')

    -- First Run
    breedOnce(true)
    action.analyzeStorage(false)
    action.restockAll()

    -- Loop
    while breedOnce(false) do
        breedRound = breedRound + 1
        action.restockAll()
    end

    -- Terminated Early
    if events.needExit() then
        action.restockAll()
    end

    -- Finish
    if config.cleanUp then
        action.cleanUp()
    end

    events.unhookEvents()
    print('autoBreed: Complete!')
end

main()
