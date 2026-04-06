local action = require('action')
local database = require('database')
local gps = require('gps')
local scanner = require('scanner')
local config = require('config')
local events = require('events')
local breedRound = 0
local parents = {nil,nil};
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
            if config.keepParents then
                action.transplant(gps.workingSlotToPos(slot), gps.storageSlotToPos(database.nextStorageSlot()))
                action.placeCropStick(2)
                database.addToStorage(crop)
            else
                action.deweed()
                action.placeCropStick()
            end
        else
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
        if #database.getStorage() >= config.storageFarmArea then
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

local function main()
    action.initWork()
    print('autoBreed: Scanning Farm')

    -- First Run
    breedOnce(true)
    action.analyzeStorage(false)
    action.restockAll()
    updateLowest()

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
