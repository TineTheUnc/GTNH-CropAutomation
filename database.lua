local storage = {}
local reverseStorage = {}
local farm = {}

-- ======================== WORKING FARM ========================

local function getFarm()
    return farm
end

local function updateFarm(slot, crop)
    farm[slot] = crop
end

-- ======================== STORAGE FARM ========================

local function getStorage()
    return storage
end

local function hasStorageCropName(name)
    for _, crop in pairs(storage) do
        if crop and crop.name == name then
            return true
        end
    end
    return false
end

local function removeFromStorage(slot)
    local removedCrop = storage[slot]
    if not removedCrop then
        return
    end

    storage[slot] = nil
    if not hasStorageCropName(removedCrop.name) then
        reverseStorage[removedCrop.name] = nil
    end
end

local function resetStorage()
    storage = {}
    reverseStorage = {}
end

local function updateStorage(slot, crop)
    storage[slot] = crop
    reverseStorage[crop.name] = true
end


local function addToStorage(crop)
    local slot = 1
    while storage[slot] ~= nil do
        slot = slot + 1
    end

    storage[slot] = crop
    reverseStorage[crop.name] = true
    return slot
end


local function existInStorage(crop)
    return reverseStorage[crop.name] == true
end


local function storageCount()
    local count = 0
    for _, crop in pairs(storage) do
        if crop ~= nil then
            count = count + 1
        end
    end
    return count
end

local function isStorageFull(maxSlots)
    return storageCount() >= maxSlots
end

local function nextStorageSlot()
    local slot = 1
    while storage[slot] ~= nil do
        slot = slot + 1
    end
    return slot
end

local function isStorageEmpty()
    for _, crop in pairs(storage) do
        if crop ~= nil then
            return false
        end
    end
    return true
end



return {
    getFarm = getFarm,
    updateFarm = updateFarm,
    updateStorage = updateStorage,
    getStorage = getStorage,
    resetStorage = resetStorage,
    addToStorage = addToStorage,
    existInStorage = existInStorage,
    storageCount = storageCount,
    isStorageFull = isStorageFull,
    nextStorageSlot = nextStorageSlot,
    isStorageEmpty = isStorageEmpty,
    removeFromStorage = removeFromStorage
}