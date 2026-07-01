local pd <const> = playdate

PlayerProfileStore = {}

local DATASTORE_PATH <const> = "data/save/playerProfile"
local DEFAULT_NAME <const> = "Wee Tarot"
local MAX_NAME_LENGTH <const> = 16
local DEFAULT_DATE_DISPLAY_REVERSED <const> = false
local DEFAULT_ENTRIES_LIST_DESCENDING <const> = false
local DEFAULT_SOUND_MODE <const> = 1
local DEFAULT_SFX_ENABLED <const> = true

local function readProfile()
    local stored = pd.datastore.read(DATASTORE_PATH)
    if type(stored) ~= "table" then
        return {}
    end

    return stored
end

local function writeProfile(profile)
    pd.datastore.write(profile, DATASTORE_PATH, true)
end

local function sanitizeName(name)
    if type(name) ~= "string" then
        return DEFAULT_NAME
    end

    local trimmed = name:match("^%s*(.-)%s*$") or ""
    if #trimmed > MAX_NAME_LENGTH then
        trimmed = string.sub(trimmed, 1, MAX_NAME_LENGTH)
    end

    if #trimmed == 0 then
        return DEFAULT_NAME
    end

    return trimmed
end

local function sanitizeDateDisplayReversed(value)
    return value == true
end

local function sanitizeEntriesListDescending(value)
    return value == true
end

local function sanitizeSoundMode(value)
    local numeric = tonumber(value)
    if not numeric then
        return DEFAULT_SOUND_MODE
    end

    numeric = math.floor(numeric)
    if numeric < 1 or numeric > 3 then
        return DEFAULT_SOUND_MODE
    end

    return numeric
end

local function sanitizeSfxEnabled(value)
    if value == nil then
        return DEFAULT_SFX_ENABLED
    end

    return value ~= false
end

function PlayerProfileStore.getName()
    local profile = readProfile()
    return sanitizeName(profile.name)
end

function PlayerProfileStore.setName(name)
    local profile = readProfile()
    local sanitized = sanitizeName(name)
    profile.name = sanitized
    profile.dateDisplayReversed = sanitizeDateDisplayReversed(profile.dateDisplayReversed)
    profile.entriesListDescending = sanitizeEntriesListDescending(profile.entriesListDescending)
    writeProfile(profile)
    return sanitized
end

function PlayerProfileStore.getDateDisplayReversed()
    local profile = readProfile()
    local value = profile.dateDisplayReversed
    if value == nil then
        return DEFAULT_DATE_DISPLAY_REVERSED
    end

    return sanitizeDateDisplayReversed(value)
end

function PlayerProfileStore.setDateDisplayReversed(value)
    local profile = readProfile()
    profile.name = sanitizeName(profile.name)
    profile.dateDisplayReversed = sanitizeDateDisplayReversed(value)
    profile.entriesListDescending = sanitizeEntriesListDescending(profile.entriesListDescending)
    writeProfile(profile)
    return profile.dateDisplayReversed
end

function PlayerProfileStore.getEntriesListDescending()
    local profile = readProfile()
    local value = profile.entriesListDescending
    if value == nil then
        return DEFAULT_ENTRIES_LIST_DESCENDING
    end

    return sanitizeEntriesListDescending(value)
end

function PlayerProfileStore.setEntriesListDescending(value)
    local profile = readProfile()
    profile.name = sanitizeName(profile.name)
    profile.dateDisplayReversed = sanitizeDateDisplayReversed(profile.dateDisplayReversed)
    profile.entriesListDescending = sanitizeEntriesListDescending(value)
    writeProfile(profile)
    return profile.entriesListDescending
end

function PlayerProfileStore.getSoundMode()
    local profile = readProfile()
    return sanitizeSoundMode(profile.soundMode)
end

function PlayerProfileStore.setSoundMode(value)
    local profile = readProfile()
    profile.name = sanitizeName(profile.name)
    profile.dateDisplayReversed = sanitizeDateDisplayReversed(profile.dateDisplayReversed)
    profile.entriesListDescending = sanitizeEntriesListDescending(profile.entriesListDescending)
    profile.soundMode = sanitizeSoundMode(value)
    writeProfile(profile)
    return profile.soundMode
end

function PlayerProfileStore.getSfxEnabled()
    local profile = readProfile()
    return sanitizeSfxEnabled(profile.sfxEnabled)
end

function PlayerProfileStore.setSfxEnabled(value)
    local profile = readProfile()
    profile.name = sanitizeName(profile.name)
    profile.dateDisplayReversed = sanitizeDateDisplayReversed(profile.dateDisplayReversed)
    profile.entriesListDescending = sanitizeEntriesListDescending(profile.entriesListDescending)
    profile.soundMode = sanitizeSoundMode(profile.soundMode)
    profile.sfxEnabled = sanitizeSfxEnabled(value)
    writeProfile(profile)
    return profile.sfxEnabled
end

function PlayerProfileStore.formatDiaryDate(date)
    if type(date) ~= "string" then
        return "-- - ---"
    end

    local dayStr, monthStr = string.match(date, "^(%d%d)%-(%d%d)%-%d%d%d%d$")
    if not dayStr or not monthStr then
        dayStr, monthStr = string.match(date, "^(%d%d)/(%d%d)/%d%d%d%d$")
    end

    local day = tonumber(dayStr)
    local month = tonumber(monthStr)
    if not day or not month then
        return date
    end

    local months = {
        "JAN", "FEB", "MAR", "APR", "MAY", "JUN",
        "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"
    }
    local monthName = months[month]
    if not monthName then
        return date
    end

    local suffix = "th"
    if day == 1 or day == 21 or day == 31 then
        suffix = "st"
    elseif day == 2 or day == 22 then
        suffix = "nd"
    elseif day == 3 or day == 23 then
        suffix = "rd"
    end

    local dayText = tostring(day) .. suffix
    if PlayerProfileStore.getDateDisplayReversed() then
        return monthName .. " - " .. dayText
    end

    return dayText .. " - " .. monthName
end

function PlayerProfileStore.getMaxNameLength()
    return MAX_NAME_LENGTH
end

return PlayerProfileStore