local pd <const> = playdate
local gfx <const> = pd.graphics

local ImageCache = {}

-- simple LRU cache for gfx.image objects
local cache = {}
local order = {} -- list of keys, front = most recently used
local totalBytes = 0
local defaults = {
    maxEntries = 2,
    maxBytes = 131072, -- 128KB default
}

local function estimateBytes(w, h)
    if not w or not h then return 0 end
    return math.ceil((w * h) / 8)
end

local function touchKey(key)
    for i, k in ipairs(order) do
        if k == key then
            table.remove(order, i)
            table.insert(order, 1, key)
            return
        end
    end
    table.insert(order, 1, key)
end

local function evictIfNeeded()
    while (#order > defaults.maxEntries) or (totalBytes > defaults.maxBytes) do
        local evictKey = order[#order]
        if not evictKey then break end
        local entry = cache[evictKey]
        if entry then
            totalBytes = totalBytes - (entry.size or 0)
            cache[evictKey] = nil
        end
        table.remove(order)
    end
end

function ImageCache.setup(opts)
    opts = opts or {}
    defaults.maxEntries = opts.maxEntries or defaults.maxEntries
    defaults.maxBytes = opts.maxBytes or defaults.maxBytes
end

-- getOrCreate: returns existing image or calls createFn() to produce one and store it
function ImageCache.getOrCreate(key, createFn, opts)
    if not key then return nil end
    local entry = cache[key]
    if entry and entry.image then
        touchKey(key)
        return entry.image
    end

    -- create
    local img = nil
    if createFn then
        img = createFn()
    end
    if not img then return nil end

    local w = (opts and opts.width) or 0
    local h = (opts and opts.height) or 0
    local sz = estimateBytes(w, h)
    cache[key] = { image = img, size = sz }
    totalBytes = totalBytes + sz
    touchKey(key)
    evictIfNeeded()
    return img
end

function ImageCache.clear()
    cache = {}
    order = {}
    totalBytes = 0
end

function ImageCache.info()
    return {
        entries = #order,
        bytes = totalBytes,
        maxEntries = defaults.maxEntries,
        maxBytes = defaults.maxBytes,
    }
end

return ImageCache
