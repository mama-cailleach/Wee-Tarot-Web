local pd <const> = playdate

import "data/spreadReadingData"

DiaryStore = {}

local INDEX_PATH <const> = "data/save/diaryIndex"
local LEGACY_PATH <const> = "data/save/diaryEntries"
local BUNDLED_FALLBACK_PATH <const> = "data/save/diaryEntries.json"
local ENTRY_PATH_PREFIX <const> = "data/save/diaryEntry_"

local SCHEMA_VERSION <const> = 3
local LEGACY_INDEX_SCHEMA <const> = 2

local entriesCache = nil
local indexCache = nil
local persistedIds = {}
local pendingDiskWrite = false
local pendingFlushEntryId = nil
local framesUntilFlush = 0
local browserCacheByDescending = {}

-- Idle backup: flush to disk if the player stays on the hub a while.
local FLUSH_IDLE_FRAMES <const> = 180

local function entryPathForId(entryId)
    return ENTRY_PATH_PREFIX .. tostring(entryId)
end

local function sanitizeEntry(raw)
    if type(raw) ~= "table" then
        return nil
    end

    local date = raw.date or "00-00-0000"
    local time = raw.time or "00.00"
    local spreadType = SpreadReadingData.normalizeSpreadKey(raw.spreadType or "unknown")

    if type(time) == "string" then
        time = string.gsub(time, ":", ".")
    end

    if type(time) ~= "string" or not string.match(time, "^%d%d%.%d%d$") then
        time = "00.00"
    end

    local cards = {}
    if type(raw.cards) == "table" then
        for _, card in ipairs(raw.cards) do
            if type(card) == "table" then
                local sanitizedCard = {
                    name = card.name,
                    number = card.number,
                    suit = card.suit,
                    inverted = card.inverted == true,
                    position = card.position
                }

                if type(card.themes) == "table" then
                    local themes = {}
                    for _, theme in ipairs(card.themes) do
                        if type(theme) == "string" and theme ~= "" then
                            table.insert(themes, theme)
                        end
                    end
                    if #themes > 0 then
                        sanitizedCard.themes = themes
                    end
                end

                table.insert(cards, sanitizedCard)
            end
        end
    end

    local entry = {
        date = date,
        time = time,
        spreadType = spreadType,
        cards = cards
    }

    if type(raw.id) == "number" then
        entry.id = raw.id
    end

    local prevId = tonumber(raw.prevId)
    if prevId and prevId > 0 then
        entry.prevId = prevId
    end

    return entry
end

local function sanitizeEntries(rawEntries)
    local entries = {}
    if type(rawEntries) ~= "table" then
        return entries
    end

    for _, entry in ipairs(rawEntries) do
        local sanitized = sanitizeEntry(entry)
        if sanitized then
            table.insert(entries, sanitized)
        end
    end

    return entries
end

local function readBundledFallback()
    local fallback = json.decodeFile(BUNDLED_FALLBACK_PATH)
    if type(fallback) ~= "table" then
        return {}
    end

    return sanitizeEntries(fallback.entries)
end

local function ensureIndexCache()
    if indexCache then
        return indexCache
    end

    indexCache = {
        schemaVersion = SCHEMA_VERSION,
        nextId = 1,
        headId = nil
    }

    return indexCache
end

local function linkEntriesNewestFirst(entries)
    for i, entry in ipairs(entries or {}) do
        local olderEntry = entries[i + 1]
        if olderEntry and olderEntry.id then
            entry.prevId = olderEntry.id
        else
            entry.prevId = nil
        end
    end
end

local function buildIndexFromEntries(entries)
    local index = ensureIndexCache()

    for i, entry in ipairs(entries or {}) do
        if not entry.id then
            entry.id = i
        end
    end

    linkEntriesNewestFirst(entries)

    index.headId = entries[1] and entries[1].id or nil
    index.nextId = #entries + 1
    return index
end

local function writeIndexToDisk()
    if not indexCache then
        return false
    end

    pd.datastore.write({
        schemaVersion = SCHEMA_VERSION,
        nextId = indexCache.nextId,
        headId = indexCache.headId
    }, INDEX_PATH, true)

    return true
end

local function writeEntryToDisk(entry)
    if not entry or type(entry.id) ~= "number" then
        return false
    end

    local payload = {
        schemaVersion = SCHEMA_VERSION,
        date = entry.date,
        time = entry.time,
        spreadType = entry.spreadType,
        cards = entry.cards
    }

    if type(entry.prevId) == "number" then
        payload.prevId = entry.prevId
    end

    pd.datastore.write(payload, entryPathForId(entry.id), true)

    persistedIds[entry.id] = true
    return true
end

local function readEntryFromDisk(entryId)
    local stored = pd.datastore.read(entryPathForId(entryId))
    if type(stored) ~= "table" then
        return nil
    end

    local entry = sanitizeEntry(stored)
    if entry then
        entry.id = entryId
    end

    return entry
end

local function loadEntriesFromOrderList(orderList)
    local entries = {}
    persistedIds = {}

    for _, entryId in ipairs(orderList or {}) do
        local numericId = tonumber(entryId)
        if numericId then
            local entry = readEntryFromDisk(numericId)
            if entry then
                table.insert(entries, entry)
                persistedIds[numericId] = true
            end
        end
    end

    return entries
end

local function loadEntriesFromHeadChain(headId, nextId)
    indexCache = {
        schemaVersion = SCHEMA_VERSION,
        nextId = tonumber(nextId) or 1,
        headId = tonumber(headId)
    }

    local entries = {}
    persistedIds = {}

    local currentId = indexCache.headId
    local safety = 0

    while currentId and safety < 10000 do
        safety += 1
        local entry = readEntryFromDisk(currentId)
        if not entry then
            break
        end

        table.insert(entries, entry)
        persistedIds[currentId] = true
        currentId = entry.prevId
    end

    if #entries == 0 then
        return nil
    end

    return entries
end

local function persistV3ChainMetadata(entries)
    linkEntriesNewestFirst(entries)
    buildIndexFromEntries(entries)

    for _, entry in ipairs(entries) do
        writeEntryToDisk(entry)
    end

    writeIndexToDisk()
end

local function migrateLegacyIndexToV3(entries)
    print(string.format("[DiaryStore] upgrading index v%d -> v%d (%d entries)", LEGACY_INDEX_SCHEMA, SCHEMA_VERSION, #entries))
    persistV3ChainMetadata(entries)
end

local function loadEntriesFromIndex()
    local storedIndex = pd.datastore.read(INDEX_PATH)
    if type(storedIndex) ~= "table" then
        return nil
    end

    local schemaVersion = tonumber(storedIndex.schemaVersion) or LEGACY_INDEX_SCHEMA

    if schemaVersion >= SCHEMA_VERSION then
        local headId = tonumber(storedIndex.headId)
        if not headId or headId <= 0 then
            indexCache = {
                schemaVersion = SCHEMA_VERSION,
                nextId = tonumber(storedIndex.nextId) or 1,
                headId = nil
            }
            persistedIds = {}
            return {}
        end

        return loadEntriesFromHeadChain(headId, storedIndex.nextId)
    end

    if type(storedIndex.order) ~= "table" or #storedIndex.order == 0 then
        return nil
    end

    local entries = loadEntriesFromOrderList(storedIndex.order)
    if #entries == 0 then
        return nil
    end

    indexCache = {
        schemaVersion = LEGACY_INDEX_SCHEMA,
        nextId = tonumber(storedIndex.nextId) or (#storedIndex.order + 1),
        headId = entries[1] and entries[1].id or nil
    }

    migrateLegacyIndexToV3(entries)
    return entries
end

local function migrateLegacyBlob(legacy)
    local entries = sanitizeEntries(legacy.entries)
    if #entries == 0 then
        return nil
    end

    persistV3ChainMetadata(entries)

    pd.datastore.write({
        schemaVersion = 1,
        migrated = true
    }, LEGACY_PATH, true)

    print(string.format("[DiaryStore] migrated %d legacy entries to sharded storage", #entries))
    return entries
end

local function loadEntriesFromStorage()
    local indexedEntries = loadEntriesFromIndex()
    if indexedEntries then
        return indexedEntries
    end

    local legacy = pd.datastore.read(LEGACY_PATH)
    if type(legacy) == "table" and legacy.migrated ~= true and type(legacy.entries) == "table" and #legacy.entries > 0 then
        local migrated = migrateLegacyBlob(legacy)
        if migrated then
            return migrated
        end
    end

    local bundledEntries = readBundledFallback()
    if #bundledEntries > 0 then
        buildIndexFromEntries(bundledEntries)
        return bundledEntries
    end

    ensureIndexCache()
    return {}
end

local function assignEntryId(entry)
    local index = ensureIndexCache()
    local entryId = index.nextId
    index.nextId = entryId + 1
    entry.id = entryId
    entry.prevId = index.headId
    index.headId = entryId
    return entryId
end

local function flushUnpersistedEntries()
    if not entriesCache then
        return false
    end

    local wroteAny = false

    for _, entry in ipairs(entriesCache) do
        if entry.id and not persistedIds[entry.id] then
            if writeEntryToDisk(entry) then
                wroteAny = true
            end
        end
    end

    return wroteAny
end

local function findCachedEntryById(entryId)
    if not entriesCache or type(entryId) ~= "number" then
        return nil
    end

    for _, entry in ipairs(entriesCache) do
        if entry.id == entryId then
            return entry
        end
    end

    return nil
end

--- Normal post-reading save: write only the newly appended entry, not all RAM-only history.
local function flushPendingEntryOnly()
    if type(pendingFlushEntryId) ~= "number" then
        return flushUnpersistedEntries()
    end

    if persistedIds[pendingFlushEntryId] then
        return false
    end

    local entry = findCachedEntryById(pendingFlushEntryId)
    if not entry then
        return false
    end

    return writeEntryToDisk(entry)
end

function DiaryStore.getEntries()
    if entriesCache then
        return entriesCache
    end

    entriesCache = loadEntriesFromStorage()
    return entriesCache
end

function DiaryStore.invalidateCache()
    entriesCache = nil
    indexCache = nil
    persistedIds = {}
    pendingFlushEntryId = nil
    browserCacheByDescending = {}
end

function DiaryStore.invalidateBrowserCache()
    browserCacheByDescending = {}
end

local function formatPreviewTime(timeText)
    if type(timeText) ~= "string" then
        return "00.00"
    end

    timeText = string.gsub(timeText, ":", ".")

    if not string.match(timeText, "^%d%d%.%d%d$") then
        return "00.00"
    end

    return timeText
end

local function parseDiaryDate(dateText)
    local dayText, monthText, yearText = string.match(dateText or "", "^(%d%d)%-(%d%d)%-(%d%d%d%d)$")
    if not dayText or not monthText or not yearText then
        return nil
    end

    local day = tonumber(dayText)
    local month = tonumber(monthText)
    local year = tonumber(yearText)
    if not day or not month or not year then
        return nil
    end

    return {
        day = day,
        month = month,
        year = year,
        date = dateText
    }
end

local function buildBrowserData(entries, entriesListDescending)
    local yearLookup = {}
    local years = {}

    for entryIndex, entry in ipairs(entries or {}) do
        local parsed = parseDiaryDate(entry.date)
        if parsed then
            local yearBucket = yearLookup[parsed.year]
            if not yearBucket then
                yearBucket = {
                    year = parsed.year,
                    months = {},
                    monthLookup = {}
                }
                yearLookup[parsed.year] = yearBucket
                table.insert(years, yearBucket)
            end

            local monthBucket = yearBucket.monthLookup[parsed.month]
            if not monthBucket then
                monthBucket = {
                    month = parsed.month,
                    days = {},
                    dayLookup = {},
                    entries = {}
                }
                yearBucket.monthLookup[parsed.month] = monthBucket
                table.insert(yearBucket.months, monthBucket)
            end

            local dayBucket = monthBucket.dayLookup[parsed.day]
            if not dayBucket then
                dayBucket = {
                    day = parsed.day,
                    date = parsed.date,
                    entries = {}
                }
                monthBucket.dayLookup[parsed.day] = dayBucket
                table.insert(monthBucket.days, dayBucket)
            end

            table.insert(dayBucket.entries, entry)
            table.insert(monthBucket.entries, {
                entry = entry,
                day = parsed.day,
                date = parsed.date,
                sortOrder = entryIndex
            })
        end
    end

    table.sort(years, function(left, right)
        return left.year > right.year
    end)

    for _, yearBucket in ipairs(years) do
        table.sort(yearBucket.months, function(left, right)
            return left.month < right.month
        end)

        for _, monthBucket in ipairs(yearBucket.months) do
            table.sort(monthBucket.days, function(left, right)
                return left.day < right.day
            end)

            table.sort(monthBucket.entries, function(left, right)
                if left.day == right.day then
                    local leftTime = formatPreviewTime(left.entry and left.entry.time)
                    local rightTime = formatPreviewTime(right.entry and right.entry.time)

                    if leftTime == rightTime then
                        return left.sortOrder < right.sortOrder
                    end

                    if entriesListDescending then
                        return leftTime > rightTime
                    end

                    return leftTime < rightTime
                end

                if entriesListDescending then
                    return left.day > right.day
                end

                return left.day < right.day
            end)
        end
    end

    return { years = years }
end

function DiaryStore.getBrowserData(entriesListDescending)
    local descending = entriesListDescending == true
    if browserCacheByDescending[descending] then
        return browserCacheByDescending[descending]
    end

    local data = buildBrowserData(DiaryStore.getEntries(), descending)
    browserCacheByDescending[descending] = data
    return data
end

function DiaryStore.prewarmDiaryUI()
    DiaryStore.getBrowserData(false)
    DiaryStore.getBrowserData(true)
    if GameAssets and GameAssets.prewarmDiaryListAssets then
        GameAssets.prewarmDiaryListAssets()
    end
end

function DiaryStore.scheduleAppendPresanitized(sanitizedEntry)
    if not sanitizedEntry then
        return false
    end

    local entries = DiaryStore.getEntries()
    pendingFlushEntryId = assignEntryId(sanitizedEntry)
    table.insert(entries, 1, sanitizedEntry)
    entriesCache = entries

    pendingDiskWrite = true
    framesUntilFlush = FLUSH_IDLE_FRAMES
    DiaryStore.invalidateBrowserCache()
    return true
end

function DiaryStore.scheduleAppend(entry)
    return DiaryStore.scheduleAppendPresanitized(sanitizeEntry(entry))
end

function DiaryStore.queueCompletedReading(spreadType, cards)
    return DiaryStore.scheduleAppend({
        date = DiaryStore.formatDateFromSystem(),
        time = DiaryStore.formatTimeFromSystem(),
        spreadType = spreadType,
        cards = cards
    })
end

function DiaryStore.flushPendingEntryFiles()
    if not pendingDiskWrite then
        return false
    end

    local t0 = pd.getElapsedTime()
    flushPendingEntryOnly()
    print(string.format("[DiaryStore] flush entry %s %.1fms", tostring(pendingFlushEntryId), (pd.getElapsedTime() - t0) * 1000))
    return true
end

function DiaryStore.finishPendingFlush()
    if not pendingDiskWrite then
        return false
    end

    local t0 = pd.getElapsedTime()
    writeIndexToDisk()

    pendingDiskWrite = false
    pendingFlushEntryId = nil
    framesUntilFlush = 0

    print(string.format("[DiaryStore] flush index %.1fms", (pd.getElapsedTime() - t0) * 1000))
    return true
end

function DiaryStore.flushPendingAppend()
    if not pendingDiskWrite then
        return false
    end

    local t0 = pd.getElapsedTime()
    DiaryStore.flushPendingEntryFiles()
    DiaryStore.finishPendingFlush()
    print(string.format("[DiaryStore] flush total %.1fms", (pd.getElapsedTime() - t0) * 1000))
    return true
end

function DiaryStore.tickFlush(isSceneTransitioning)
    if not pendingDiskWrite then
        framesUntilFlush = 0
        return false
    end

    if isSceneTransitioning then
        framesUntilFlush = FLUSH_IDLE_FRAMES
        return false
    end

    if framesUntilFlush > 0 then
        framesUntilFlush -= 1
        return false
    end

    return DiaryStore.flushPendingAppend()
end

function DiaryStore.hasPendingAppend()
    return pendingDiskWrite
end

function DiaryStore.warmCache()
    DiaryStore.getEntries()
    DiaryStore.getBrowserData(false)
    DiaryStore.getBrowserData(true)
    if GameAssets and GameAssets.prewarmDiaryListAssets then
        GameAssets.prewarmDiaryListAssets()
    end
end

function DiaryStore.formatDateFromSystem()
    local now = pd.getTime and pd.getTime()
    if not now or not now.day or not now.month or not now.year then
        return "00-00-0000"
    end

    return string.format("%02d-%02d-%04d", now.day, now.month, now.year)
end

function DiaryStore.formatTimeFromSystem()
    local now = pd.getTime and pd.getTime()
    if not now or now.hour == nil or now.minute == nil then
        return "00.00"
    end

    return string.format("%02d.%02d", now.hour, now.minute)
end

function DiaryStore.appendEntry(entry, alreadySanitized)
    local sanitized = alreadySanitized and entry or sanitizeEntry(entry)
    if not sanitized then
        return false
    end

    DiaryStore.scheduleAppendPresanitized(sanitized)
    return DiaryStore.flushPendingAppend()
end

return DiaryStore
