local pd <const> = playdate
local gfx <const> = pd.graphics

GameAssets = {}

local cache = {
    dinahBG = nil,
    deckLaying = nil,
    explodeDeck = nil,
    scaledCard = nil,
    shuffle = nil,
    explodeFinale = nil,
    cardSpinSlide = nil,
    tarotPlayspace = nil,
    darkcloth = nil,
    scrollBox = nil,
    clothBitsEdges = nil,
    placementZone = nil,
    placementZoneDiamond = nil,
    revealTable = nil,
    iconTriSmol = nil,
    journalFrames = nil,
    diaryAnim = nil,
    moonKey = nil,
    lockMov = nil,
    journal1 = nil,
    iconKnotSmol = nil,
}

local preloadSteps = {
    function() cache.dinahBG = gfx.imagetable.new("images/bg/dinahBG-table-400-266") end,
    function() cache.deckLaying = gfx.imagetable.new("images/shuffleAnimation/deck_laying_full_lower-table-400-240") end,
    function() cache.explodeDeck = gfx.imagetable.new("images/shuffleAnimation/exploding_deck1-table-400-240") end,
    function() cache.scaledCard = gfx.imagetable.new("images/shuffleAnimation/scaled_card-table-400-240") end,
    function() cache.shuffle = gfx.imagetable.new("images/shuffleAnimation/1_card_shuffle-table-400-240") end,
    function() cache.explodeFinale = gfx.imagetable.new("images/shuffleAnimation/explode_finale-table-400-240") end,
    function() cache.cardSpinSlide = gfx.imagetable.new("images/shuffleAnimation/card_spin_slide-table-400-240") end,
    function() cache.tarotPlayspace = gfx.image.new("images/bg/tarot_playspace") end,
    function() cache.darkcloth = gfx.image.new("images/bg/darkcloth") end,
    function() cache.scrollBox = gfx.image.new("images/textScroll/scroll1b") end,
    function() cache.clothBitsEdges = gfx.image.new("images/bg/cloth_bits_edges") end,
    function() cache.placementZone = gfx.image.new("images/decknback/placementzone_no_diamond") end,
    function() cache.placementZoneDiamond = gfx.image.new("images/decknback/placementzone_diamond") end,
    function() cache.revealTable = gfx.imagetable.new("images/shuffleAnimation/reveal-table-236-342") end,
    function() cache.iconTriSmol = gfx.image.new("images/bg/icon_tri_smol") end,
    function() cache.journalFrames = gfx.image.new("images/bg/journal_frames2") end,
    function() cache.diaryAnim = gfx.imagetable.new("images/bg/diary_anim-table-400-273") end,
    function() cache.moonKey = gfx.imagetable.new("images/bg/moonkey-table-400-273") end,
    function() cache.lockMov = gfx.imagetable.new("images/bg/lock_mov-table-400-273") end,
    function() cache.journal1 = gfx.image.new("images/bg/journal1") end,
    function() cache.iconKnotSmol = gfx.image.new("images/bg/icon_knot1_smol") end,
}

local preloadIndex = 0

function GameAssets.beginPreload()
    preloadIndex = 0
end

--- Runs one preload step. Returns true while more steps remain, false when complete.
function GameAssets.advancePreload()
    preloadIndex += 1
    local step = preloadSteps[preloadIndex]
    if not step then
        return false
    end
    step()
    return preloadIndex < #preloadSteps
end

function GameAssets.isPreloadComplete()
    return preloadIndex >= #preloadSteps
end

function GameAssets.getDinahImagetable()
    cache.dinahBG = cache.dinahBG or gfx.imagetable.new("images/bg/dinahBG-table-400-266")
    return cache.dinahBG
end

function GameAssets.getDeckLayingImagetable()
    cache.deckLaying = cache.deckLaying or gfx.imagetable.new("images/shuffleAnimation/deck_laying_full_lower-table-400-240")
    return cache.deckLaying
end

function GameAssets.getExplodeDeckImagetable()
    cache.explodeDeck = cache.explodeDeck or gfx.imagetable.new("images/shuffleAnimation/exploding_deck1-table-400-240")
    return cache.explodeDeck
end

function GameAssets.getScaledCardImagetable()
    cache.scaledCard = cache.scaledCard or gfx.imagetable.new("images/shuffleAnimation/scaled_card-table-400-240")
    return cache.scaledCard
end

function GameAssets.getShuffleImagetable()
    cache.shuffle = cache.shuffle or gfx.imagetable.new("images/shuffleAnimation/1_card_shuffle-table-400-240")
    return cache.shuffle
end

function GameAssets.getExplodeFinaleImagetable()
    cache.explodeFinale = cache.explodeFinale or gfx.imagetable.new("images/shuffleAnimation/explode_finale-table-400-240")
    return cache.explodeFinale
end

function GameAssets.getCardSpinSlideImagetable()
    cache.cardSpinSlide = cache.cardSpinSlide or gfx.imagetable.new("images/shuffleAnimation/card_spin_slide-table-400-240")
    return cache.cardSpinSlide
end

function GameAssets.getTarotPlayspaceImage()
    cache.tarotPlayspace = cache.tarotPlayspace or gfx.image.new("images/bg/tarot_playspace")
    return cache.tarotPlayspace
end

function GameAssets.getDarkclothImage()
    cache.darkcloth = cache.darkcloth or gfx.image.new("images/bg/darkcloth")
    return cache.darkcloth
end

function GameAssets.getScrollBoxImage()
    cache.scrollBox = cache.scrollBox or gfx.image.new("images/textScroll/scroll1b")
    return cache.scrollBox
end

function GameAssets.getClothBitsEdgesImage()
    cache.clothBitsEdges = cache.clothBitsEdges or gfx.image.new("images/bg/cloth_bits_edges")
    return cache.clothBitsEdges
end

function GameAssets.getPlacementZoneImage()
    cache.placementZone = cache.placementZone or gfx.image.new("images/decknback/placementzone_no_diamond")
    return cache.placementZone
end

function GameAssets.getPlacementZoneDiamondImage()
    cache.placementZoneDiamond = cache.placementZoneDiamond or gfx.image.new("images/decknback/placementzone_diamond")
    return cache.placementZoneDiamond
end

function GameAssets.getRevealImagetable()
    cache.revealTable = cache.revealTable or gfx.imagetable.new("images/shuffleAnimation/reveal-table-236-342")
    return cache.revealTable
end

function GameAssets.getIconTriSmolImage()
    cache.iconTriSmol = cache.iconTriSmol or gfx.image.new("images/bg/icon_tri_smol")
    return cache.iconTriSmol
end

function GameAssets.getJournalFramesImage()
    cache.journalFrames = cache.journalFrames or gfx.image.new("images/bg/journal_frames2")
    return cache.journalFrames
end

function GameAssets.getDiaryAnimImagetable()
    cache.diaryAnim = cache.diaryAnim or gfx.imagetable.new("images/bg/diary_anim-table-400-273")
    return cache.diaryAnim
end

function GameAssets.getMoonKeyImagetable()
    cache.moonKey = cache.moonKey or gfx.imagetable.new("images/bg/moonkey-table-400-273")
    return cache.moonKey
end

function GameAssets.getLockMovImagetable()
    cache.lockMov = cache.lockMov or gfx.imagetable.new("images/bg/lock_mov-table-400-273")
    return cache.lockMov
end

function GameAssets.getJournal1Image()
    cache.journal1 = cache.journal1 or gfx.image.new("images/bg/journal1")
    return cache.journal1
end

function GameAssets.getIconKnotSmolImage()
    cache.iconKnotSmol = cache.iconKnotSmol or gfx.image.new("images/bg/icon_knot1_smol")
    return cache.iconKnotSmol
end

--- Touch diary list assets + browser index (call from hub idle, not on B press).
function GameAssets.prewarmDiaryListAssets()
    GameAssets.getJournal1Image()
    GameAssets.getIconKnotSmolImage()
end
