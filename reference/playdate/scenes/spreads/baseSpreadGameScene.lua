import "../../scripts/deck"
import "../../data/save/diaryStore"
import "../../data/spreadReadingData"

local pd <const> = playdate
local gfx <const> = pd.graphics

class('BaseSpreadGameScene').extends(gfx.sprite)

local DEFAULT_FIRST_PROMPTS = {
    "Set your intentions, let the cards\nhear your silent whispers.",
    "Let your energy flow... \nand the answers will find you.",
    "Clear your mind, focus your heart,\nand allow the truth to unfold.",
    "Shuffle with purpose. Your\nquestion shapes the path ahead.",
    "Breathe deep, steady your spirit,\nand invite clarity into the cards.",
    "The deck awaits your touch,\nguide it with your thoughts.",
    "With each shuffle, your destiny\nstirs. Trust the journey."
}

local CARDS_PER_CREATION_BATCH <const> = 2
local SFX_DEFER_MS <const> = 33

local function clamp01(value)
    if value == nil then return 0 end
    if value < 0 then return 0 end
    if value > 1 then return 1 end
    return value
end

function BaseSpreadGameScene:init(config, restoreState)
    BaseSpreadGameScene.super.init(self)

    self.config = config
    self.deck = Deck()
    self.selectedDeck = selectedDeck or "full"

    self.bgSprite = gfx.sprite.new(GameAssets.getTarotPlayspaceImage())
    self.bgSprite:moveTo(200, 120)
    self.bgSprite:add()

    self.state = "shuffle"
    self.shuffleAnimSprite = nil
    self.shuffleFinishTimer = nil
    self.shuffleFrame = 1
    self.shuffleFrameCount = 1
    self.deckLayingSprite = nil
    self.deckLayingIntroTimer = nil
    self.revealSprite = nil
    self.spinSlideAnimSprite = nil
    self.spinSlideTriggered = false
    self.spinSlideTriggerSpinCount = math.random(5, 8)
    self.shuffleSpinCount = 0
    self.lastCrankTime = 0

    self.playerCards = {}
    self.playerCardNumbers = {}
    self.playerCardSuits = {}
    self.playerCardsInverted = {}
    self.drawnCardVisuals = {}

    self.cardPositions = config.cardPositions
    self.revealTimers = {}
    self.revealedTimersStarted = false
    self.drawCardPool = nil
    self.drawCardNextIndex = 1
    self.drawCardsBatchTimer = nil

    self.defaultSelectedCardIndex = 1
    self.selectionReady = restoreState ~= nil
    self.selectedCardIndex = restoreState and self.defaultSelectedCardIndex or nil
    self.selectedScale = config.selectedScale or config.defaultScale
    self.selectedCardZoomed = false

    if config.enableCardDimming == nil then
        self.enableCardDimming = true
    else
        self.enableCardDimming = config.enableCardDimming
    end
    self.nonSelectedDimAlpha = clamp01(config.nonSelectedDimAlpha or 0.5)
    self.selectedDimAlpha = clamp01(config.selectedDimAlpha or 0)
    if config.dimNonSelectedWhenZoomed == nil then
        self.dimNonSelectedWhenZoomed = true
    else
        self.dimNonSelectedWhenZoomed = config.dimNonSelectedWhenZoomed
    end
    self.cardImageCache = {}

    self.crankSoundPlaying = false
    self.crankInactivityTimer = nil

    self.firstPrompts = config.firstPrompts or DEFAULT_FIRST_PROMPTS
    self.firstPromptX = config.firstPromptX or 20
    self.firstPromptY = config.firstPromptY or 4
    self.firstPromptDelayPerChar = config.firstPromptDelayPerChar or 40
    self.firstPromptVisibleTime = config.firstPromptVisibleTime or 1500
    self.firstPromptFadeOutTime = config.firstPromptFadeOutTime or 40
    self.firstPromptRepeatMin = config.firstPromptRepeatMin or 20000
    self.firstPromptRepeatMax = config.firstPromptRepeatMax or 25000

    self.firstPromptSprite = nil
    self.firstPromptTimer = nil
    self.promptTypeTimers = {}
    self.entrySetupTimer = nil
    self.restoreSetupTimer = nil
    self.confirmToMenu = restoreState and restoreState.confirmToMenu or false
    self.diaryEntrySaved = false
    self.diarySpreadKey = (restoreState and restoreState.spreadKey) or config.spreadKey or "unknown"
    self.cardThemes = restoreState and restoreState.cardThemes or nil

    if restoreState then
        self.state = "fortune"
        self:startRestoreEntry(restoreState)
    elseif config.enableIntroAnimation == false then
        self.state = "shuffle"
        self:startShuffleEntry()
    else
        self:startIntroEntry()
    end

    self:add()
end

function BaseSpreadGameScene:startRestoreEntry(restoreState)
    if self.restoreSetupTimer then
        self.restoreSetupTimer:remove()
        self.restoreSetupTimer = nil
    end

    self.restoreSetupTimer = pd.timer.performAfterDelay(0, function()
        self.restoreSetupTimer = nil
        self:showPlacementSprite(nil, nil, true)
        self:restoreSpreadState(restoreState)
    end)
end

function BaseSpreadGameScene:startIntroEntry()
    if self.deckLayingIntroTimer then
        self.deckLayingIntroTimer:remove()
        self.deckLayingIntroTimer = nil
    end

    self.state = "intro"
    self.deckLayingIntroTimer = pd.timer.performAfterDelay(1000, function()
        self.deckLayingIntroTimer = nil
        if self.state ~= "intro" then
            return
        end

        local coinFlip = math.random(1, 2)
        if coinFlip == 1 then
            self:startDeckLayingIntro()
        else
            self:setupCardExplodeIntro()
        end
    end)
end

function BaseSpreadGameScene:startShuffleEntry()
    if self.entrySetupTimer then
        self.entrySetupTimer:remove()
        self.entrySetupTimer = nil
    end

    -- Spread heavy setup across the frame after init (fade-out first frame stays light).
    self.entrySetupTimer = pd.timer.performAfterDelay(0, function()
        self.entrySetupTimer = nil
        if self.state ~= "shuffle" then
            return
        end
        self:showFirstPrompt()
        self:setup16CardShuffleAnimation()
        self.shuffleFrame = 1
        self.shuffleFrameCount = self.shuffleAnimSprite and self.shuffleAnimSprite.imagetable:getLength() or 1
    end)
end

function BaseSpreadGameScene:restoreSpreadState(restoreState)
    if not restoreState then return end

    self:clearDrawnCards()

    local cardNames = restoreState.cardNames or {}
    local cardNumbers = restoreState.cardNumbers or {}
    local cardSuits = restoreState.cardSuits or {}
    local cardInverted = restoreState.cardInverted or {}

    for index = 1, self.config.cardCount do
        local cardNumber = cardNumbers[index]
        local cardSuit = cardSuits[index]
        if cardNumber and cardSuit then
            local visual = Card(cardNumber, cardSuit)
            visual:moveTo(self.cardPositions[index].x, self.cardPositions[index].y)
            visual:setVisible(true)

            local isInverted = cardInverted[index] or false
            visual.inverted = isInverted
            
            local cardRotations = self.config.cardRotations
            local baseRotation = isInverted and 180 or 0
            local customRotation = cardRotations and cardRotations[index]
            local finalRotation = customRotation or baseRotation
            visual:setRotation(finalRotation)

            self:cacheCardImageForVisual(index, visual)

            table.insert(self.drawnCardVisuals, visual)
            table.insert(self.playerCards, cardNames[index])
            table.insert(self.playerCardNumbers, cardNumber)
            table.insert(self.playerCardSuits, cardSuit)
            table.insert(self.playerCardsInverted, isInverted)
        end
    end

    self.selectionReady = true
    self.selectedCardZoomed = false
    self:selectCard(restoreState.selectedCardIndex or self.selectedCardIndex)
end

function BaseSpreadGameScene:showPromptTextTypewriter(text, x, y, delayPerChar, visibleTime, fadeOutTime)
    local width, height = gfx.getTextSize(text)
    if width == 0 or height == 0 then width, height = 10, 10 end

    local promptSprite = gfx.sprite.new()
    promptSprite:setCenter(0, 0)
    promptSprite:moveTo(x or 8, y or 8)
    promptSprite:add()

    local currentLength = 0
    local function updateText()
        currentLength += 1
        local shownText = string.sub(text, 1, currentLength)
        local textImage = gfx.image.new(width, height)
        gfx.pushContext(textImage)
            gfx.setColor(gfx.kColorWhite)
            gfx.drawTextAligned(shownText, 0, 0, kTextAlignment.left)
        gfx.popContext()
        promptSprite:setImage(textImage)
    end

    local function trackTimer(timer)
        table.insert(self.promptTypeTimers, timer)
        return timer
    end

    local typeTimer
    typeTimer = trackTimer(pd.timer.keyRepeatTimerWithDelay(delayPerChar or 40, delayPerChar or 40, function()
        if currentLength < #text then
            updateText()
        else
            typeTimer:remove()
            trackTimer(pd.timer.performAfterDelay(visibleTime or 1200, function()
                local removeLength = #text
                local function updateRemoveText()
                    removeLength -= 1
                    local shownText = string.sub(text, 1, removeLength)
                    local textImage = gfx.image.new(width, height)
                    gfx.pushContext(textImage)
                        gfx.setColor(gfx.kColorWhite)
                        gfx.drawTextAligned(shownText, 0, 0, kTextAlignment.left)
                    gfx.popContext()
                    promptSprite:setImage(textImage)
                end

                local removeTimer
                removeTimer = trackTimer(pd.timer.keyRepeatTimerWithDelay(fadeOutTime or delayPerChar or 40, fadeOutTime or delayPerChar or 40, function()
                    if removeLength > 0 then
                        updateRemoveText()
                    else
                        removeTimer:remove()
                        promptSprite:remove()
                    end
                end))
            end))
        end
    end))

    updateText()
    return promptSprite
end

function BaseSpreadGameScene:showFirstPrompt()
    if self.firstPromptSprite then
        self.firstPromptSprite:remove()
        self.firstPromptSprite = nil
    end

    local prompt = self.firstPrompts[math.random(#self.firstPrompts)]
    self.firstPromptSprite = self:showPromptTextTypewriter(
        prompt,
        self.firstPromptX,
        self.firstPromptY,
        self.firstPromptDelayPerChar,
        self.firstPromptVisibleTime,
        self.firstPromptFadeOutTime
    )

    if self.firstPromptTimer then
        self.firstPromptTimer:remove()
        self.firstPromptTimer = nil
    end

    self.firstPromptTimer = pd.timer.performAfterDelay(math.random(self.firstPromptRepeatMin, self.firstPromptRepeatMax), function()
        if self.state == "shuffle" and not pd.buttonIsPressed(pd.kButtonA) then
            self:showFirstPrompt()
        end
    end)
    --Sound.playSFX("witchpad")
end

function BaseSpreadGameScene:startDeckLayingIntro()
    if self.deckLayingSprite then
        self.deckLayingSprite:remove()
        self.deckLayingSprite = nil
    end

    self.deckLayingSprite = AnimatedSprite.new(GameAssets.getDeckLayingImagetable())
    self.deckLayingSprite:addState("laying", 1, 125, {
        tickStep = 1,
        loop = false,
        onAnimationEndEvent = function()
            if self.deckLayingSprite then
                self.deckLayingSprite:remove()
                self.deckLayingSprite = nil
            end

            self.state = "shuffle"
            self:showFirstPrompt()
            self:setup16CardShuffleAnimation()
            self.shuffleFrame = 1
            self.shuffleFrameCount = self.shuffleAnimSprite and self.shuffleAnimSprite.imagetable:getLength() or 1
        end
    }, true)
    self.deckLayingSprite:moveTo(205, 120)
    self.deckLayingSprite:add()
    self.deckLayingSprite:playAnimation()
    Sound.playSFX("cards2_slow")
end

function BaseSpreadGameScene:setupCardExplodeIntro()
    if self.explodeAnimSprite then self.explodeAnimSprite:remove() self.explodeAnimSprite = nil end
    self.explodeAnimSprite = AnimatedSprite.new(GameAssets.getExplodeDeckImagetable())
    self.explodeAnimSprite:addState("explode", 1, 72, {
        reverse = true,
        tickStep = 1,
        loop = false,
        onAnimationEndEvent = function()
            if self.explodeAnimSprite then
                self.explodeAnimSprite:remove()
                self.explodeAnimSprite = nil
            end

            self.state = "shuffle"
            self:showFirstPrompt()
            self:setup16CardShuffleAnimation()
            self.shuffleFrame = 1
            self.shuffleFrameCount = self.shuffleAnimSprite and self.shuffleAnimSprite.imagetable:getLength() or 1
        end
    }, true)
    self.explodeAnimSprite:moveTo(207, 132)
    self.explodeAnimSprite:add()
    self.explodeAnimSprite:playAnimation()
    Sound.playSFX("cards2_fast2")
end

function BaseSpreadGameScene:clearShufflePrompts()
    if self.firstPromptSprite then
        self.firstPromptSprite:remove()
        self.firstPromptSprite = nil
    end

    if self.firstPromptTimer then
        self.firstPromptTimer:remove()
        self.firstPromptTimer = nil
    end

    for _, timer in ipairs(self.promptTypeTimers) do
        if timer then timer:remove() end
    end
    self.promptTypeTimers = {}
    --Sound.stopSFX("witchpad")
end

function BaseSpreadGameScene:setup16CardShuffleAnimation()
    if self.shuffleAnimSprite then self.shuffleAnimSprite:remove() self.shuffleAnimSprite = nil end
    self.shuffleAnimSprite = AnimatedSprite.new(GameAssets.getShuffleImagetable())
    self.shuffleAnimSprite:addState("idle", 1, 1)
    self.shuffleAnimSprite:addState("shuffle", 1, 60, { tickStep = 1 })
    self.shuffleAnimSprite:moveTo(220, 135)
    self.shuffleAnimSprite:add()
    self.shuffleAnimSprite:playAnimation()
    self.shuffleFrameCount = self.shuffleAnimSprite.imagetable:getLength()
end

function BaseSpreadGameScene:setupCardExplodeAnimation()
    if self.explodeAnimSprite then self.explodeAnimSprite:remove() self.explodeAnimSprite = nil end

    local useFinale = self.config.useExplodeFinaleOnShuffleFinish == true
    local imagetable = useFinale and GameAssets.getExplodeFinaleImagetable() or GameAssets.getExplodeDeckImagetable()
    local frameCount = useFinale and 100 or 72

    self.explodeAnimSprite = AnimatedSprite.new(imagetable)
    self.explodeAnimSprite:addState("explode", 1, frameCount, {
        tickStep = 1,
        loop = false,
        onAnimationEndEvent = function()
            if self.explodeAnimSprite then
                self.explodeAnimSprite:remove()
                self.explodeAnimSprite = nil
            end
        end
    }, true)
    self.explodeAnimSprite:moveTo(useFinale and 208 or 207, useFinale and 125 or 132)
    self.explodeAnimSprite:add()
    self.explodeAnimSprite:playAnimation()
end

function BaseSpreadGameScene:startDeckLayingEnding()
    if self.deckLayingSprite then
        self.deckLayingSprite:remove()
        self.deckLayingSprite = nil
    end

    self.deckLayingSprite = AnimatedSprite.new(GameAssets.getDeckLayingImagetable())
    self.deckLayingSprite:addState("laying", 1, 126, {
        reverse=true,
        tickStep = 1,
        loop = false,
        onAnimationEndEvent = function()
            if self.deckLayingSprite then
                self.deckLayingSprite:remove()
                self.deckLayingSprite = nil
            end
        end
    }, true)
    self.deckLayingSprite:moveTo(205, 120)
    self.deckLayingSprite:add()
    self.deckLayingSprite:playAnimation()
end

function BaseSpreadGameScene:scaleAnimation(x, y)
    if self.scaleSprite then self.scaleSprite:remove() self.scaleSprite = nil end
    self.scaleSprite = AnimatedSprite.new(GameAssets.getScaledCardImagetable())
    self.scaleSprite:addState("scale", 1, 60, {
        tickStep = self.config.scaleAnimationTickStep or 0.5,
        loop = false,
        onAnimationEndEvent = function()
            if self.scaleSprite then
                self.scaleSprite:remove()
                self.scaleSprite = nil
            end
            if self.config.useDiamondPlacementZone then
                self:showPlacementSprite()
            else
                self:showPlacementSprite(x, y)
            end
            self.state = "revealed"
        end
    }, true)
    self.scaleSprite:moveTo(x or 180, y or 120)
    self.scaleSprite:add()
    self.scaleSprite:changeState("scale", true)
    self.scaleSprite:playAnimation()
end

function BaseSpreadGameScene:playRevealBackAnimation(x, y)
    if self.revealSprite then
        self.revealSprite:remove()
        self.revealSprite = nil
    end

    local revealTable = GameAssets.getRevealImagetable()
    self.revealSprite = AnimatedSprite.new(revealTable)
    self.revealSprite:addState("animate", 3, 6, {
        tickStep = 1,
        loop = false,
        xScale = 0.6,
        yScale = 0.6,
        onAnimationEndEvent = function()
            if self.revealSprite then
                self.revealSprite:remove()
                self.revealSprite = nil
            end
            if self.state == "revealing" then
                self.state = "revealed"
            end
        end
    }, true)
    self.revealSprite:addState("reveal", 1, 6, { tickStep = 1 }, false)
    self.revealSprite:moveTo(x or 200, y or 110)
    self.revealSprite:add()
    self.revealSprite:changeState("animate", true)
    self.revealSprite:playAnimation()
end

function BaseSpreadGameScene:showPlacementSprite(x, y, addImmediately)
    local placementX = x or 200
    local placementY = y or 120
    local revealX = 200
    local revealY = 110
    local shouldAddPlacementNow = addImmediately == true

    if self.config.useDiamondPlacementZone then
        placementX = 200
        placementY = 120
        revealX = 200
        revealY = 110
        shouldAddPlacementNow = true
    end

    if self.bgSprite then
        if self.config.useDarkclothPlacement then
            self.bgSprite:setImage(GameAssets.getDarkclothImage())
        else
            self.bgSprite:setImage(GameAssets.getClothBitsEdgesImage())
        end
    end

    if not self.cardPlacementSprite then
        if self.config.useRevealBackAnimation then
            self:playRevealBackAnimation(revealX, revealY)
        end

        local zoneImage = self.config.useDiamondPlacementZone
            and GameAssets.getPlacementZoneDiamondImage()
            or GameAssets.getPlacementZoneImage()

        self.cardPlacementSprite = gfx.sprite.new(zoneImage)
        self.cardPlacementSprite:setScale(1)
        self.cardPlacementSprite:moveTo(placementX, placementY)

        if not self.config.useDiamondPlacementZone then
            self.cardPlacementSprite:setZIndex(200)
            self.cardPlacementSprite:setImageDrawMode(gfx.kDrawModeXOR)
        end

        if shouldAddPlacementNow then
            self.cardPlacementSprite:add()
        end
    end

    if self.shuffleAnimSprite then
        self.shuffleAnimSprite:remove()
        self.shuffleAnimSprite = nil
    end
end

function BaseSpreadGameScene:triggerSpinSlideAnimation()
    if self.spinSlideTriggered then return end
    if self.state ~= "shuffle" then return end

    self.spinSlideTriggered = true
    self.state = "revealing"
    self:clearShufflePrompts()

    if self.shuffleFinishTimer then
        self.shuffleFinishTimer:remove()
        self.shuffleFinishTimer = nil
    end

    if self.crankInactivityTimer then
        self.crankInactivityTimer:remove()
        self.crankInactivityTimer = nil
    end

    if self.crankSoundPlaying then
        Sound.stopCrankLoop()
        self.crankSoundPlaying = false
    end

    if self.shuffleAnimSprite then
        self.shuffleAnimSprite:remove()
        self.shuffleAnimSprite = nil
    end

    if self.spinSlideAnimSprite then
        self.spinSlideAnimSprite:remove()
        self.spinSlideAnimSprite = nil
    end

    self.spinSlideAnimSprite = AnimatedSprite.new(GameAssets.getCardSpinSlideImagetable())
    self.spinSlideAnimSprite:addState("slide", 1, 60, {
        tickStep = 1,
        loop = false,
        onAnimationEndEvent = function()
            if self.spinSlideAnimSprite then
                self.spinSlideAnimSprite:remove()
                self.spinSlideAnimSprite = nil
            end
            self:showPlacementSprite()
        end
    }, true)
    self.spinSlideAnimSprite:moveTo(205, 150)
    self.spinSlideAnimSprite:add()
    self.spinSlideAnimSprite:playAnimation()
    ScreenShake.screenShake(400, 4)
end

function BaseSpreadGameScene:advanceShuffleFrames(frameAdvance)
    if not self.shuffleAnimSprite or self.spinSlideTriggered then return end

    local frameCount = self.shuffleFrameCount or 60
    local steps = math.abs(frameAdvance)
    if steps == 0 then return end

    local direction = frameAdvance > 0 and 1 or -1

    for _ = 1, steps do
        local nextFrame = self.shuffleFrame + direction

        if nextFrame > frameCount then
            nextFrame = 1
            self.shuffleSpinCount += 1
        elseif nextFrame < 1 then
            nextFrame = frameCount
        end

        self.shuffleFrame = nextFrame
        self.shuffleAnimSprite:setFrame(self.shuffleFrame)

        if direction > 0
            and self.shuffleSpinCount >= self.spinSlideTriggerSpinCount
            and self.shuffleFrame == 1 then
            self:triggerSpinSlideAnimation()
            return
        end
    end
end

function BaseSpreadGameScene:drawSingleCardLegacy()
    if self.spinSlideAnimSprite then
        self.spinSlideAnimSprite:remove()
        self.spinSlideAnimSprite = nil
    end

    self:clearDrawnCards()

    local cardDrawed, cardNumber, cardSuit = self:drawCardByDeckSelection()
    if cardNumber and cardSuit then
        local visual = Card(cardNumber, cardSuit)
        visual:moveTo(self.cardPositions[1].x, self.cardPositions[1].y)
        visual:setScale(self.config.defaultScale)

        if visual.inverted then
            visual:setRotation(180)
        else
            visual:setRotation(0)
        end

        self:cacheCardImageForVisual(1, visual)

        table.insert(self.drawnCardVisuals, visual)
        table.insert(self.playerCards, cardDrawed)
        table.insert(self.playerCardNumbers, cardNumber)
        table.insert(self.playerCardSuits, cardSuit)
        table.insert(self.playerCardsInverted, visual.inverted or false)

        self:playRevealBackAnimation(200, 110)
    end

    if self.cardPlacementSprite then
        self.cardPlacementSprite:add()
    end

    self.selectionReady = true
    self.selectedCardIndex = 1
    self.selectedCardZoomed = false
    self:selectCard(1)
    self.state = "fortune"
    Sound.playSFX("tuin")
end

function BaseSpreadGameScene:drawCardByDeckSelection()
    self.selectedDeck = selectedDeck or "full"

    if self.selectedDeck == "major" then
        return self.deck:drawMajor()
    elseif self.selectedDeck == "minor" then
        return self.deck:drawMinorArcana()
    elseif self.selectedDeck == "cups" or self.selectedDeck == "wands" or self.selectedDeck == "swords" or self.selectedDeck == "pentacles" then
        return self.deck:drawFromSuit(self.selectedDeck)
    elseif self.selectedDeck == "alternate" then
        return self.deck:drawAlternate()
    end

    return self.deck:drawFullDeck()
end

function BaseSpreadGameScene:clearDrawCardsBatch()
    if self.drawCardsBatchTimer then
        self.drawCardsBatchTimer:remove()
        self.drawCardsBatchTimer = nil
    end
    self.drawCardPool = nil
    self.drawCardNextIndex = 1
end

function BaseSpreadGameScene:clearDrawnCards()
    self:clearDrawCardsBatch()
    for _, sprite in ipairs(self.drawnCardVisuals) do
        sprite:remove()
    end
    self:clearCardImageCache()
    self.drawnCardVisuals = {}
    self.playerCards = {}
    self.playerCardNumbers = {}
    self.playerCardSuits = {}
    self.playerCardsInverted = {}
end

function BaseSpreadGameScene:createDimmedImage(baseImage, alpha)
    if not baseImage then return nil end
    local normalizedAlpha = clamp01(alpha)
    if normalizedAlpha <= 0 then
        return baseImage
    end

    local width, height = baseImage:getSize()
    local dimmedImage = gfx.image.new(width, height)
    gfx.pushContext(dimmedImage)
        baseImage:draw(0, 0)
        local blackOverlay = gfx.image.new(width, height, gfx.kColorBlack)
        blackOverlay:drawFaded(0, 0, normalizedAlpha, gfx.image.kDitherTypeBayer8x8)
    gfx.popContext()

    return dimmedImage
end

function BaseSpreadGameScene:cacheCardImageForVisual(index, visual)
    if not self.enableCardDimming or not visual then return end
    if self.cardImageCache[index] then return end

    local originalImage = visual:getImage()
    if not originalImage then return end

    self.cardImageCache[index] = {
        original = originalImage,
        dimmed = self:createDimmedImage(originalImage, self.nonSelectedDimAlpha),
        selected = self:createDimmedImage(originalImage, self.selectedDimAlpha),
    }
end

function BaseSpreadGameScene:ensureZoomCacheForIndex(index, visual)
    if not self.enableCardDimming or not visual then return end

    local cache = self.cardImageCache[index]
    if not cache or cache.zoomCacheBuilt then return end
    cache.zoomCacheBuilt = true

    local zoomImage = visual.getZoomImage and visual:getZoomImage() or nil
    cache.zoomOriginal = zoomImage
    cache.zoomDimmed = zoomImage and self:createDimmedImage(zoomImage, self.nonSelectedDimAlpha) or nil
    cache.zoomSelected = zoomImage and self:createDimmedImage(zoomImage, self.selectedDimAlpha) or nil
end

function BaseSpreadGameScene:clearCardImageCache()
    self.cardImageCache = {}
end

function BaseSpreadGameScene:getCardImageForState(index, isSelected)
    if not self.enableCardDimming then return nil end

    local cache = self.cardImageCache[index]
    if not cache then return nil end

    if isSelected then
        if self.selectedCardZoomed then
            local visual = self.drawnCardVisuals[index]
            if visual then
                self:ensureZoomCacheForIndex(index, visual)
                cache = self.cardImageCache[index]
            end
            return cache.zoomSelected or cache.zoomOriginal or cache.selected or cache.original
        end
        return cache.selected or cache.original
    end

    if self.selectedCardZoomed and not self.dimNonSelectedWhenZoomed then
        return cache.original
    end

    return cache.dimmed or cache.original
end

function BaseSpreadGameScene:applyCardImageForState(index, visual, isSelected)
    if not self.enableCardDimming or not visual then return end

    local targetImage = self:getCardImageForState(index, isSelected)
    if targetImage then
        visual:setImage(targetImage)
    end
end

function BaseSpreadGameScene:buildDrawPoolForSelection()
    self.selectedDeck = selectedDeck or "full"

    local function appendDeckCards(pool, deckCards, suitIndex)
        for cardNumber, cardName in ipairs(deckCards or {}) do
            table.insert(pool, {
                name = cardName,
                number = cardNumber,
                suit = suitIndex
            })
        end
    end

    local pool = {}
    if self.selectedDeck == "major" then
        appendDeckCards(pool, self.deck.majorArcanaDeck, 5)
    elseif self.selectedDeck == "minor" then
        appendDeckCards(pool, self.deck.cupsDeck, 1)
        appendDeckCards(pool, self.deck.wandsDeck, 2)
        appendDeckCards(pool, self.deck.swordsDeck, 3)
        appendDeckCards(pool, self.deck.pentaclesDeck, 4)
    elseif self.selectedDeck == "cups" then
        appendDeckCards(pool, self.deck.cupsDeck, 1)
    elseif self.selectedDeck == "wands" then
        appendDeckCards(pool, self.deck.wandsDeck, 2)
    elseif self.selectedDeck == "swords" then
        appendDeckCards(pool, self.deck.swordsDeck, 3)
    elseif self.selectedDeck == "pentacles" then
        appendDeckCards(pool, self.deck.pentaclesDeck, 4)
    elseif self.selectedDeck == "alternate" then
        -- For alternate mode, create a pool with random suits in order
        -- We'll get all 5 suits, then repeat as needed
        local suitSequence = {}
        local cardCount = self.config.cardCount
        local fullCycle = {1, 2, 3, 4, 5} -- cups, wands, swords, pentacles, major
        
        -- Shuffle the cycle
        for i = #fullCycle, 2, -1 do
            local j = math.random(i)
            fullCycle[i], fullCycle[j] = fullCycle[j], fullCycle[i]
        end
        
        -- Build sequence by repeating and shuffling the cycle for each full rotation
        local currentCycle = 1
        for i = 1, cardCount do
            local cycleIndex = ((i - 1) % 5) + 1
            
            -- After every 5 cards, reshuffle the cycle
            if cycleIndex == 1 and i > 1 then
                for j = #fullCycle, 2, -1 do
                    local k = math.random(j)
                    fullCycle[j], fullCycle[k] = fullCycle[k], fullCycle[j]
                end
            end
            
            table.insert(suitSequence, fullCycle[cycleIndex])
        end
        
        -- Now build the pool using the suit sequence
        for _, suitIndex in ipairs(suitSequence) do
            local selectedDeck = self.deck.allDecks[suitIndex]
            if selectedDeck and #selectedDeck > 0 then
                local cardNumber = math.random(1, #selectedDeck)
                table.insert(pool, {
                    name = selectedDeck[cardNumber],
                    number = cardNumber,
                    suit = suitIndex
                })
            end
        end
        
        return pool
    else
        appendDeckCards(pool, self.deck.cupsDeck, 1)
        appendDeckCards(pool, self.deck.wandsDeck, 2)
        appendDeckCards(pool, self.deck.swordsDeck, 3)
        appendDeckCards(pool, self.deck.pentaclesDeck, 4)
        appendDeckCards(pool, self.deck.majorArcanaDeck, 5)
    end

    for i = #pool, 2, -1 do
        local j = math.random(i)
        pool[i], pool[j] = pool[j], pool[i]
    end

    return pool
end

function BaseSpreadGameScene:createDrawnCardVisual(index, draw)
    local cardDrawed = draw and draw.name
    local cardNumber = draw and draw.number
    local cardSuit = draw and draw.suit
    if not cardNumber or not cardSuit then return end

    local visual = Card(cardNumber, cardSuit)
    visual:moveTo(self.cardPositions[index].x, self.cardPositions[index].y)
    visual:setScale(self.config.defaultScale)
    visual:setVisible(false)

    local cardRotations = self.config.cardRotations
    if cardRotations and cardRotations[index] then
        visual:setRotation(cardRotations[index])
    end

    table.insert(self.drawnCardVisuals, visual)
    table.insert(self.playerCards, cardDrawed)
    table.insert(self.playerCardNumbers, cardNumber)
    table.insert(self.playerCardSuits, cardSuit)
    table.insert(self.playerCardsInverted, visual.inverted or false)
end

function BaseSpreadGameScene:advanceDrawCardsBatch()
    self.drawCardsBatchTimer = nil

    if not self.drawCardPool then return end

    local cardCount = self.config.cardCount
    local batchEnd = math.min(self.drawCardNextIndex + CARDS_PER_CREATION_BATCH - 1, cardCount)

    for index = self.drawCardNextIndex, batchEnd do
        self:createDrawnCardVisual(index, self.drawCardPool[index])
    end

    self.drawCardNextIndex = batchEnd + 1

    if self.drawCardNextIndex <= cardCount then
        self.drawCardsBatchTimer = pd.timer.performAfterDelay(SFX_DEFER_MS, function()
            self:advanceDrawCardsBatch()
        end)
        return
    end

    self:finishDrawCards()
end

function BaseSpreadGameScene:finishDrawCards()
    self.drawCardPool = nil
    self.drawCardNextIndex = 1

    if self.selectionReady then
        self:selectCard(self.selectedCardIndex or self.defaultSelectedCardIndex)
    end

    self.drawCardsBatchTimer = pd.timer.performAfterDelay(SFX_DEFER_MS, function()
        self.drawCardsBatchTimer = nil
        self:revealCardsSequentially()
        Sound.playSFX("pad_b")
    end)
end

function BaseSpreadGameScene:drawCardsLogic()
    self:clearDrawnCards()

    self.drawCardPool = self:buildDrawPoolForSelection()
    self.drawCardNextIndex = 1
    self:advanceDrawCardsBatch()
end

function BaseSpreadGameScene:getCardPositionForSelection(index, isSelected)
    local basePosition = self.cardPositions and self.cardPositions[index]
    if not isSelected then
        return basePosition
    end

    local selectedPositions = self.config.selectedCardPositions
    local zoomPositions = self.config.zoomCardPositions
    local selectedPosition = selectedPositions and selectedPositions[index]
    local zoomPosition = zoomPositions and zoomPositions[index]

    if self.selectedCardZoomed then
        return zoomPosition or selectedPosition or basePosition
    end

    return selectedPosition or basePosition
end

function BaseSpreadGameScene:selectCard(index)
    if #self.drawnCardVisuals == 0 then return end
    if not self.selectionReady then return end

    local total = #self.drawnCardVisuals
    local targetIndex = index or self.selectedCardIndex or self.defaultSelectedCardIndex or 1
    local wrappedIndex = ((targetIndex - 1) % total) + 1
    self.selectedCardIndex = wrappedIndex

    local baseZ = self.config.cardBaseZIndex or 100
    local zoomedSelectedZ = self.config.zoomedSelectedCardZIndex or (baseZ + 100)
    local selectedZ = self.config.selectedCardZIndex or zoomedSelectedZ

    for i, visual in ipairs(self.drawnCardVisuals) do
        local isSelected = i == self.selectedCardIndex
        local targetScale = self.config.defaultScale
        local targetZ = baseZ + i
        if isSelected then
            targetScale = self.selectedScale
            targetZ = self.selectedCardZoomed and zoomedSelectedZ or selectedZ
        end

        local targetPosition = self:getCardPositionForSelection(i, isSelected)
        if targetPosition then
            visual:moveTo(targetPosition.x, targetPosition.y)
        end

        self:applyCardImageForState(i, visual, isSelected)
        visual:setScale(targetScale)
        visual:setZIndex(targetZ)
    end

    if self.cardPlacementSprite then
        local selectedCard = self.drawnCardVisuals[self.selectedCardIndex]
        if selectedCard then
            self.cardPlacementSprite:moveTo(selectedCard.x, selectedCard.y)
            
            local cardRotations = self.config.cardRotations
            if cardRotations and cardRotations[self.selectedCardIndex] then
                self.cardPlacementSprite:setRotation(cardRotations[self.selectedCardIndex])
            else
                self.cardPlacementSprite:setRotation(0)
            end
        end
    end
end

function BaseSpreadGameScene:cycleSelectedCard(direction)
    if #self.drawnCardVisuals == 0 then return end
    if not self.selectionReady then return end
    self.selectedCardZoomed = false
    self:selectCard(self.selectedCardIndex + direction)
end

function BaseSpreadGameScene:buildDiaryCards()
    local cards = {}

    for index, cardName in ipairs(self.playerCards or {}) do
        local inverted = self.playerCardsInverted and self.playerCardsInverted[index] == true or false
        local themes = self.cardThemes and self.cardThemes[index]
        if type(themes) ~= "table" or #themes == 0 then
            themes = SpreadReadingData.pickKeywords(cardName, inverted, 3)
        end

        local cardEntry = {
            name = cardName,
            number = self.playerCardNumbers and self.playerCardNumbers[index] or nil,
            suit = self.playerCardSuits and self.playerCardSuits[index] or nil,
            inverted = inverted,
            position = index,
            themes = themes
        }

        table.insert(cards, cardEntry)
    end

    return cards
end

function BaseSpreadGameScene:queueReadingToDiary()
    if self.diaryEntrySaved then
        return
    end

    DiaryStore.queueCompletedReading(self.diarySpreadKey, self:buildDiaryCards())
    self.diaryEntrySaved = true
end

function BaseSpreadGameScene:finishReading()
    self:queueReadingToDiary()
    Sound.prepareForBufferScene()
    SCENE_MANAGER:switchScene(BufferScene)
end

function BaseSpreadGameScene:revealCardsSequentially()
    local revealDelay = self.config.revealDelay
    for i, visual in ipairs(self.drawnCardVisuals) do
        local timer = pd.timer.performAfterDelay((i - 1) * revealDelay, function()
            if not visual then return end
            visual:setVisible(true)
            self:cacheCardImageForVisual(i, visual)
            local playRevealSfx = function()
                Sound.playSFX("cards_fast3")
            end
            if i == 1 then
                local sfxTimer = pd.timer.performAfterDelay(SFX_DEFER_MS, playRevealSfx)
                table.insert(self.revealTimers, sfxTimer)
            else
                playRevealSfx()
            end
        end)
        table.insert(self.revealTimers, timer)
    end

    pd.timer.performAfterDelay((#self.drawnCardVisuals * revealDelay) + 200, function()
        if self.cardPlacementSprite then
            self.cardPlacementSprite:add()
        end
        self.selectionReady = true
        if self.selectedCardIndex == nil then
            self.selectedCardIndex = self.defaultSelectedCardIndex
        end

        self.selectedCardZoomed = false
        self:selectCard(self.selectedCardIndex or self.defaultSelectedCardIndex)
        self.state = "fortune"
        Sound.playSFX("tuin")
    end)
end

function BaseSpreadGameScene:zoomInOutCards()
    if #self.drawnCardVisuals == 0 then return end
    if not self.selectionReady then return end

    if pd.buttonJustPressed(pd.kButtonLeft) then
        self:cycleSelectedCard(-1)
    end

    if pd.buttonJustPressed(pd.kButtonRight) then
        self:cycleSelectedCard(1)
    end

    if pd.buttonJustPressed(pd.kButtonUp) then
        self.selectedCardZoomed = true
        self:selectCard(self.selectedCardIndex)
    end

    if pd.buttonJustPressed(pd.kButtonDown) then
        self.selectedCardZoomed = false
        self:selectCard(self.selectedCardIndex)
    end
end

function BaseSpreadGameScene:update()
    gfx.sprite.update()

    if pd.buttonJustPressed(pd.kButtonA) then
        if self.state == "shuffle" and self.shuffleAnimSprite and not self.shuffleFinishTimer then
            self:clearShufflePrompts()
            local finishFrame = self.shuffleAnimSprite.frameCount or self.shuffleFrameCount or 90
            local function advanceFrame()
                local currentFrame = self.shuffleAnimSprite._currentFrame
                if currentFrame < finishFrame then
                    Sound.playSFX("cards2_fast2")
                    self.shuffleAnimSprite:setFrame(currentFrame + 1)
                else
                    if self.shuffleFinishTimer then
                        self.shuffleFinishTimer:remove()
                        self.shuffleFinishTimer = nil
                    end
                    self.shuffleAnimSprite:changeState("idle")
                    Sound.stopSFX("cards2_fast2")
                    pd.timer.performAfterDelay(100, function()
                        if self.shuffleAnimSprite then
                            self.shuffleAnimSprite:remove()
                            self.shuffleAnimSprite = nil
                        end
                        self:setupCardExplodeAnimation()
                        
                        --[[
                        local coinFlip = math.random(1, 2)
                        if coinFlip == 1 then
                            self:setupCardExplodeAnimation()
                        else
                            self:startDeckLayingEnding()
                        end
                        ]]
                        Sound.playSFX("cards2_slow")
                        pd.timer.performAfterDelay(2500, function()
                            Sound.playSFX("cards_fast3")
                            pd.timer.performAfterDelay(300, function()
                                self:scaleAnimation(200, 110)
                            end)
                        end)
                    end)
                end
            end
            self.shuffleFinishTimer = pd.timer.keyRepeatTimerWithDelay(1000 / 500, 1000 / 500, advanceFrame)
        elseif self.state == "fortune" and #self.playerCards == self.config.cardCount then
            Sound.playSFX("cards_fast2")
            if self.confirmToMenu then
                self:finishReading()
            else
                SCENE_MANAGER:switchScene(self.config.postSceneClass, self.playerCards, self.playerCardNumbers, self.playerCardSuits, self.playerCardsInverted, self.selectedCardIndex)
            end
        end
    end

    if self.state == "revealed" and not self.revealedTimersStarted then
        self.revealedTimersStarted = true
        local drawDelay = self.config.revealedDrawDelayMs or 800
        pd.timer.performAfterDelay(drawDelay, function()
            if self.config.useLegacySingleCardDraw then
                self:drawSingleCardLegacy()
            else
                self:drawCardsLogic()
            end
        end)
    end

    if self.state == "shuffle" and self.shuffleAnimSprite and not self.shuffleFinishTimer then
        local crankChange = pd.getCrankChange()
        if crankChange ~= 0 then
            if self.config.enableSpinSlideShuffle then
                local frameAdvance = math.floor(crankChange / 7)
                if frameAdvance ~= 0 then
                    Sound.playSFX("cards2_fast2")
                    self:advanceShuffleFrames(frameAdvance)
                    if self.state ~= "shuffle" then
                        return
                    end
                end

                self.lastCrankTime = pd.getElapsedTime()

                if not self.crankSoundPlaying then
                    Sound.startCrankLoop()
                    self.crankSoundPlaying = true
                end
            else
                self.shuffleFrame = ((self.shuffleFrame - 1 + math.floor(crankChange / 7)) % self.shuffleFrameCount) + 1
                self.shuffleAnimSprite:setFrame(self.shuffleFrame)

                if not self.crankSoundPlaying then
                    Sound.startCrankLoop()
                    self.crankSoundPlaying = true
                end

                if self.crankInactivityTimer then
                    self.crankInactivityTimer:remove()
                    self.crankInactivityTimer = nil
                end

                local scene = self
                self.crankInactivityTimer = pd.timer.performAfterDelay(100, function()
                    if scene.crankSoundPlaying then
                        Sound.stopCrankLoop()
                        scene.crankSoundPlaying = false
                    end
                    scene.crankInactivityTimer = nil
                end)
            end
        end
    end

    if self.config.enableSpinSlideShuffle and self.crankSoundPlaying and pd.getElapsedTime() - self.lastCrankTime > 0.1 then
        Sound.stopCrankLoop()
        self.crankSoundPlaying = false
    end

    if self.state == "fortune" then
        self:zoomInOutCards()
    end
end

function BaseSpreadGameScene:deinit()
    if self.bgSprite then self.bgSprite:remove() self.bgSprite = nil end
    if self.deckLayingIntroTimer then self.deckLayingIntroTimer:remove() self.deckLayingIntroTimer = nil end
    if self.deckLayingSprite then self.deckLayingSprite:remove() self.deckLayingSprite = nil end
    if self.cardPlacementSprite then self.cardPlacementSprite:remove() self.cardPlacementSprite = nil end
    if self.shuffleAnimSprite then self.shuffleAnimSprite:remove() self.shuffleAnimSprite = nil end
    if self.explodeAnimSprite then self.explodeAnimSprite:remove() self.explodeAnimSprite = nil end
    if self.scaleSprite then self.scaleSprite:remove() self.scaleSprite = nil end
    if self.revealSprite then self.revealSprite:remove() self.revealSprite = nil end
    if self.spinSlideAnimSprite then self.spinSlideAnimSprite:remove() self.spinSlideAnimSprite = nil end

    for _, timer in ipairs(self.revealTimers or {}) do
        if timer then timer:remove() end
    end
    self.revealTimers = nil

    if self.shuffleFinishTimer then self.shuffleFinishTimer:remove() self.shuffleFinishTimer = nil end
    if self.crankInactivityTimer then self.crankInactivityTimer:remove() self.crankInactivityTimer = nil end

    if self.crankSoundPlaying then
        Sound.stopCrankLoop()
        self.crankSoundPlaying = false
    end

    if self.entrySetupTimer then
        self.entrySetupTimer:remove()
        self.entrySetupTimer = nil
    end
    if self.restoreSetupTimer then
        self.restoreSetupTimer:remove()
        self.restoreSetupTimer = nil
    end
    self:clearDrawCardsBatch()

    self:clearShufflePrompts()

    self:clearDrawnCards()
end
