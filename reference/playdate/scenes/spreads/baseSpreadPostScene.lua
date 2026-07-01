import "../../data/spreadReadingData"

import "../../data/save/diaryStore"

import "../../libraries/utils"



local pd <const> = playdate

local gfx <const> = pd.graphics



class('BaseSpreadPostScene').extends(gfx.sprite)



function BaseSpreadPostScene:init(config, cardNames, cardNumbers, cardSuits, cardInverted, selectedCardIndex)

    BaseSpreadPostScene.super.init(self)



    self.config = config or {}

    self.cardNames = cardNames or {}

    self.cardNumbers = cardNumbers or {}

    self.cardSuits = cardSuits or {}

    self.cardInverted = cardInverted or {}

    self.selectedCardIndex = selectedCardIndex or math.ceil((#self.cardNumbers or 1) / 2)

    self.cardSprites = {}



    self.dinahSprite = nil

    self.imagetable = nil

    self.scrollBoxImg = nil

    self.scrollBoxSprite = nil

    self.scrollBoxAnimatorIn = nil

    self.scrollBoxTimer = nil

    self.postVisualsTimer = nil



    self.textBoxWidth = 310

    self.textMaxRows = 3

    self.textFont = gfx.getSystemFont()

    self.textSections = nil

    self.textLines = nil

    self.textPages = {}

    self.pageIndex = 1

    self.textSprite = nil

    self.aButton = nil

    self.aButtonBlinkTimer = nil

    self.canButton = false

    self.diaryEntrySaved = false

    self.aButtonY = 220

    self.textBaseY = 182

    self.textAmplitude = 3.7

    self.textSpeed = 2.5

    self.oscillationStartTime = nil



    self:schedulePostVisuals()



    self:add()

end



function BaseSpreadPostScene:schedulePostVisuals()

    if self.postVisualsTimer then

        self.postVisualsTimer:remove()

        self.postVisualsTimer = nil

    end



    -- Sprites/animators are created on the next frame so scene init stays light during the fade.

    self.postVisualsTimer = pd.timer.performAfterDelay(0, function()

        self.postVisualsTimer = nil

        self:setupPostVisuals()

    end)

end



function BaseSpreadPostScene:setupPostVisuals()

    if self.dinahSprite then

        return

    end



    self.imagetable = GameAssets.getDinahImagetable()

    self.dinahSprite = AnimatedSprite.new(self.imagetable)

    self:dinahSpriteLoad()



    self.scrollBoxImg = GameAssets.getScrollBoxImage()

    self.scrollBoxSprite = gfx.sprite.new(self.scrollBoxImg)

    self.scrollBoxAnimatorIn = gfx.animator.new(2600, 300, 170, pd.easingFunctions.outBack)

    self.scrollBoxSprite:moveTo(202, 300)

    self.scrollBoxSprite:add()



    if self.scrollBoxTimer then

        self.scrollBoxTimer:remove()

        self.scrollBoxTimer = nil

    end



    local scrollDelay = self.config.scrollRevealDelayMs or 2800

    self.scrollBoxTimer = pd.timer.performAfterDelay(scrollDelay, function()

        self:onScrollBoxAnimationFinished()

    end)

end



function BaseSpreadPostScene:ensureCardThemes()
    if self.cardThemes then
        return
    end

    self.cardThemes = SpreadReadingData.buildThemesForCards(self.cardNames, self.cardInverted)
end

function BaseSpreadPostScene:ensureReadingTextBuilt()

    if self.textSections then

        return

    end

    self:ensureCardThemes()

    self.textSections = SpreadReadingData.buildPlaceholderReadingSections(self.config.spreadKey, self.cardNames, self.cardInverted, self.cardThemes)

    self.textLines = SpreadReadingData.buildPlaceholderReadingText(self.config.spreadKey, self.cardNames, self.cardInverted, self.cardThemes)

    self.textPages = self:buildTextPages()

end



function BaseSpreadPostScene:buildTextPages()

    return utils.wrapSectionsIntoPages(self.textSections or {}, self.textBoxWidth, self.textMaxRows, self.textFont)

end



function BaseSpreadPostScene:dinahSpriteLoad()

    self.dinahSprite:addState("idle", 1, 6, { tickStep = 4, yoyo = true })

    self.dinahSprite:addState("transition", 1, 20, { tickStep = 1, loop = false })

    self.dinahSprite:moveTo(200, 120)

    self.dinahSprite:add()

    self.dinahSprite:playAnimation()

end



function BaseSpreadPostScene:createCardPreviewSprites()

    local previewPositions = self.config.previewPositions or {}

    local previewScale = self.config.previewScale or 0.35



    for index, position in ipairs(previewPositions) do

        if self.cardNumbers[index] and self.cardSuits[index] then

            local cardSprite = Card(self.cardNumbers[index], self.cardSuits[index])

            cardSprite:moveTo(position.x, position.y)

            cardSprite:setScale(previewScale)

            cardSprite:setRotation(self.cardInverted[index] and 180 or 0)

            table.insert(self.cardSprites, cardSprite)

        end

    end

end



function BaseSpreadPostScene:buttonABlink()

    if self.aButton then return end

    gfx.setImageDrawMode(gfx.kDrawModeInverted)

    self.aButton = gfx.sprite.spriteWithText("A", 40, 40, nil, nil, nil, kTextAlignment.center)

    self.aButton:moveTo(360, 220)

    self.aButton:add()

    self.aButtonBlinkTimer = pd.timer.new(800, function()

        if self.aButton then

            self.aButton:setVisible(not self.aButton:isVisible())

        end

    end)

    self.aButtonBlinkTimer.repeats = true

    gfx.setImageDrawMode(gfx.kDrawModeFillBlack)

end



function BaseSpreadPostScene:removeAButton()

    if self.aButton then

        self.aButton:remove()

        self.aButton = nil

    end

    if self.aButtonBlinkTimer then

        self.aButtonBlinkTimer:remove()

        self.aButtonBlinkTimer = nil

    end

end



function BaseSpreadPostScene:showCurrentLine()

    gfx.setImageDrawMode(gfx.kDrawModeFillBlack)

    if self.textSprite then

        self.textSprite:remove()

        self.textSprite = nil

    end



    local pageLines = self.textPages[self.pageIndex] or {}

    local pageText = table.concat(pageLines, "\n")

    self.textSprite = gfx.sprite.spriteWithText(pageText, self.textBoxWidth, 200, nil, nil, nil, kTextAlignment.center)

    self.textSprite:moveTo(190, self.textBaseY)

    self.textSprite:add()

end



function BaseSpreadPostScene:onScrollBoxAnimationFinished()

    self:ensureReadingTextBuilt()

    self:showCurrentLine()

    self.canButton = true

    self.oscillationStartTime = pd.getElapsedTime()

end



function BaseSpreadPostScene:finishReading()

    self:queueReadingToDiary()

    self.canButton = false

    self:removeAButton()

    Sound.prepareForBufferScene()
    SCENE_MANAGER:switchScene(BufferScene)

end



function BaseSpreadPostScene:buildDiaryCards()
    self:ensureCardThemes()

    local cards = {}

    for index, cardName in ipairs(self.cardNames or {}) do
        local cardEntry = {
            name = cardName,
            number = self.cardNumbers and self.cardNumbers[index] or nil,
            suit = self.cardSuits and self.cardSuits[index] or nil,
            inverted = self.cardInverted and self.cardInverted[index] == true or false,
            position = index
        }

        local themes = self.cardThemes and self.cardThemes[index]
        if type(themes) == "table" and #themes > 0 then
            cardEntry.themes = themes
        end

        table.insert(cards, cardEntry)
    end

    return cards
end

function BaseSpreadPostScene:queueReadingToDiary()
    if self.diaryEntrySaved then
        return
    end

    DiaryStore.queueCompletedReading(self.config.spreadKey or "unknown", self:buildDiaryCards())
    self.diaryEntrySaved = true
end



function BaseSpreadPostScene:getSpreadGameSceneClass()

    local spreadKey = self.config.spreadKey

    if spreadKey == "one_card" then

        return OneCardGameScene

    elseif spreadKey == "three_card" then

        return ThreeCardGameScene

    elseif spreadKey == "pentagram" then

        return PentagramGameScene

    elseif spreadKey == "celtic_cross" then

        return CelticCrossGameScene

    elseif spreadKey == "horoscope" then

        return HoroscopeGameScene

    end

    return nil

end



function BaseSpreadPostScene:goBackToSpreadView()

    local gameSceneClass = self:getSpreadGameSceneClass()

    if not gameSceneClass then

        self:finishReading()

        return

    end



    self.canButton = false

    self:removeAButton()

    self:ensureReadingTextBuilt()
    self:ensureCardThemes()

    local spreadKey = self.config.spreadKey or "unknown"
    local diaryCards = self:buildDiaryCards()

    if spreadKey == "one_card" then

        SCENE_MANAGER:switchScene(CardViewScene,

            self.cardNames[1],

            self.cardNumbers[1],

            self.cardSuits[1],

            self.cardInverted[1] == true,

            spreadKey,

            diaryCards)

        return

    end



    SCENE_MANAGER:switchScene(gameSceneClass, {

        cardNames = self.cardNames,

        cardNumbers = self.cardNumbers,

        cardSuits = self.cardSuits,

        cardInverted = self.cardInverted,

        selectedCardIndex = self.selectedCardIndex,

        spreadKey = spreadKey,

        cardThemes = self.cardThemes,

        confirmToMenu = true

    })

end



function BaseSpreadPostScene:update()

    if self.scrollBoxAnimatorIn and not self.scrollBoxAnimatorIn:ended() then

        local y = self.scrollBoxAnimatorIn:currentValue()

        self.scrollBoxSprite:moveTo(202, y)

    end



    if self.canButton and not self.aButton then

        self:buttonABlink()

    end



    local offset = 0

    if self.oscillationStartTime then

        local elapsed = pd.getElapsedTime()

        offset = self.textAmplitude * math.sin((elapsed - self.oscillationStartTime) * self.textSpeed)

    end



    if self.textSprite then

        self.textSprite:moveTo(self.textSprite.x, self.textBaseY + offset)

    end

    if self.scrollBoxSprite then

        self.scrollBoxSprite:moveTo(self.scrollBoxSprite.x, 170 + offset)

    end

    if self.aButton then

        self.aButton:moveTo(self.aButton.x, self.aButtonY + offset)

    end



    if self.canButton and pd.buttonJustPressed(pd.kButtonA) then

        if self.pageIndex < #self.textPages then

            self.pageIndex = self.pageIndex + 1

            self:showCurrentLine()

        else

            self:finishReading()

        end

    end



    if self.canButton and pd.buttonJustPressed(pd.kButtonB) then
        if self.pageIndex >= #self.textPages then
        
            Sound.playABut()
            Sound.playSFX("cards_slow2")
            self:goBackToSpreadView()
        elseif self.pageIndex == (#self.textPages -1) then
            Sound.playABut()
            Sound.playSFX("cards_slow2")
            self:goBackToSpreadView()
        end

    end

end



function BaseSpreadPostScene:deinit()

    if self.postVisualsTimer then

        self.postVisualsTimer:remove()

        self.postVisualsTimer = nil

    end

    if self.dinahSprite then self.dinahSprite:remove() self.dinahSprite = nil end

    if self.scrollBoxSprite then self.scrollBoxSprite:remove() self.scrollBoxSprite = nil end

    if self.textSprite then self.textSprite:remove() self.textSprite = nil end

    if self.scrollBoxTimer then self.scrollBoxTimer:remove() self.scrollBoxTimer = nil end



    self:removeAButton()



    for _, cardSprite in ipairs(self.cardSprites or {}) do

        cardSprite:remove()

    end

    self.cardSprites = nil

    self.textLines = nil

    self.textPages = nil

end


