local pd <const> = playdate
local gfx <const> = playdate.graphics

class('SpreadSelectionScene').extends(gfx.sprite)

local deckKeys = {"full", "major", "minor", "cups", "pentacles", "swords", "wands", "alternate"}
local deckLabels = {"Full Deck", "Major Arcana", "Minor Arcana", "Cups", "Pentacles", "Swords", "Wands", "Alternate"}

function SpreadSelectionScene:init()
    SpreadSelectionScene.super.init(self)

    self.bgSprite = gfx.sprite.new(GameAssets.getDarkclothImage())
    self.bgSprite:moveTo(200, 120)
    self.bgSprite:add()

    local selectorImage = GameAssets.getIconTriSmolImage()
    self.selectorSprite = gfx.sprite.new(selectorImage)
    self.selectorSprite:setRotation(270)
    self.selectorSprite:moveTo(120, 92)
    self.selectorSprite:add()

    self.selectorSpriteRight = gfx.sprite.new(selectorImage)
    self.selectorSpriteRight:setImageFlip(gfx.kImageFlippedX)
    self.selectorSpriteRight:setRotation(270)
    self.selectorSpriteRight:moveTo(280, 92)
    self.selectorSpriteRight:add()

    self.titleText = gfx.sprite.spriteWithText("READING", 400, 200, nil, nil, nil, kTextAlignment.center)
    self.titleText:moveTo(200, 30)
    self.titleText:add()

    self.spreadOptions = {
        { label = "1-bit Fortune", key = "one_card", implemented = true },
        { label = "Root-Trunk-Branch", key = "three_card", implemented = true },
        { label = "Pentagram", key = "pentagram", implemented = true },
        { label = "Celtic Cross", key = "celtic_cross", implemented = true },
        { label = "Horoscope", key = "horoscope", implemented = true }
    }

    self.spreadOptionIndex = 1
    self.deckOptionIndex = 1
    for index, option in ipairs(self.spreadOptions) do
        if option.key == (selectedSpread or "one_card") then
            self.spreadOptionIndex = index
            break
        end
    end
    for index, key in ipairs(deckKeys) do
        if key == (selectedDeck or "full") then
            self.deckOptionIndex = index
            break
        end
    end

    selectedSpread = self.spreadOptions[self.spreadOptionIndex].key
    selectedDeck = deckKeys[self.deckOptionIndex]

    self.rowLabels = {"SPREAD", "DECK", "SEEK"}
    self.rowY = {70, 138, 212}
    self.selectedRow = 1

    self.spreadHeaderSprite = nil
    self.spreadValueSprite = nil
    self.deckHeaderSprite = nil
    self.deckValueSprite = nil
    self.goSprite = nil

    self.noticeSprite = nil
    self.noticeTimer = nil

    self:createLayoutSprites()
    self:updateSelectorPosition()

    self:add()
end

function SpreadSelectionScene:createLayoutSprites()
    self.spreadHeaderSprite = gfx.sprite.spriteWithText("SPREAD", 400, 40, nil, nil, nil, kTextAlignment.center)
    self.spreadHeaderSprite:moveTo(200, self.rowY[1])
    self.spreadHeaderSprite:add()

    self.spreadValueSprite = gfx.sprite.spriteWithText(self.spreadOptions[self.spreadOptionIndex].label, 400, 40, nil, nil, nil, kTextAlignment.center)
    self.spreadValueSprite:moveTo(200, self.rowY[1] + 28)
    self.spreadValueSprite:add()

    self.deckHeaderSprite = gfx.sprite.spriteWithText("DECK", 400, 40, nil, nil, nil, kTextAlignment.center)
    self.deckHeaderSprite:moveTo(200, self.rowY[2])
    self.deckHeaderSprite:add()

    self.deckValueSprite = gfx.sprite.spriteWithText(deckLabels[self.deckOptionIndex], 400, 40, nil, nil, nil, kTextAlignment.center)
    self.deckValueSprite:moveTo(200, self.rowY[2] + 28)
    self.deckValueSprite:add()

    self.goSprite = gfx.sprite.spriteWithText("SEEK", 400, 40, nil, nil, nil, kTextAlignment.center)
    self.goSprite:moveTo(200, self.rowY[3])
    self.goSprite:add()
end

function SpreadSelectionScene:updateSelectorPosition()
    local rowLabel = self.rowLabels[self.selectedRow]
    local textWidth = gfx.getTextSize(rowLabel)
    local offset = 18
    local y = self.rowY[self.selectedRow] - 2
    self.selectorSprite:moveTo(200 - textWidth / 2 - offset, y)
    self.selectorSpriteRight:moveTo(200 + textWidth / 2 + offset, y)
end

function SpreadSelectionScene:updateSpreadValueSprite()
    if self.spreadValueSprite then
        self.spreadValueSprite:remove()
    end
    self.spreadValueSprite = gfx.sprite.spriteWithText(self.spreadOptions[self.spreadOptionIndex].label, 400, 40, nil, nil, nil, kTextAlignment.center)
    self.spreadValueSprite:moveTo(200, self.rowY[1] + 28)
    self.spreadValueSprite:add()
end

function SpreadSelectionScene:updateDeckValueSprite()
    if self.deckValueSprite then
        self.deckValueSprite:remove()
    end
    self.deckValueSprite = gfx.sprite.spriteWithText(deckLabels[self.deckOptionIndex], 400, 40, nil, nil, nil, kTextAlignment.center)
    self.deckValueSprite:moveTo(200, self.rowY[2] + 28)
    self.deckValueSprite:add()
end

function SpreadSelectionScene:cycleSpreadOption(direction)
    local spreadCount = #self.spreadOptions
    if spreadCount == 0 then
        return
    end

    self.spreadOptionIndex = ((self.spreadOptionIndex - 1 + direction) % spreadCount) + 1
    selectedSpread = self.spreadOptions[self.spreadOptionIndex].key
    self:updateSpreadValueSprite()
end

function SpreadSelectionScene:cycleDeckOption(direction)
    local deckCount = #deckLabels
    if deckCount == 0 then
        return
    end

    self.deckOptionIndex = ((self.deckOptionIndex - 1 + direction) % deckCount) + 1
    selectedDeck = deckKeys[self.deckOptionIndex]
    self:updateDeckValueSprite()
end

function SpreadSelectionScene:showNotice(text)
    if self.noticeSprite then
        self.noticeSprite:remove()
        self.noticeSprite = nil
    end
    if self.noticeTimer then
        self.noticeTimer:remove()
        self.noticeTimer = nil
    end

    self.noticeSprite = gfx.sprite.spriteWithText(text, 400, 40, nil, nil, nil, kTextAlignment.center)
    self.noticeSprite:moveTo(200, 222)
    self.noticeSprite:add()

    self.noticeTimer = pd.timer.performAfterDelay(1200, function()
        if self.noticeSprite then
            self.noticeSprite:remove()
            self.noticeSprite = nil
        end
        self.noticeTimer = nil
    end)
end

function SpreadSelectionScene:confirmSelection()
    local option = self.spreadOptions[self.spreadOptionIndex]
    selectedSpread = option.key
    selectedDeck = deckKeys[self.deckOptionIndex]

    if not option.implemented then
        Sound.playSFX("cards_slow2")
        self:showNotice("This spread is coming soon")
        return
    end

    if option.key == "one_card" then
        Sound.playSFX("cards_fast2")
        SCENE_MANAGER:switchScene(OneCardGameScene)
        return
    elseif option.key == "three_card" then
        Sound.playSFX("cards_fast2")
        SCENE_MANAGER:switchScene(ThreeCardGameScene)
        return
    elseif option.key == "pentagram" then
        Sound.playSFX("cards_fast2")
        SCENE_MANAGER:switchScene(PentagramGameScene)
        return
    elseif option.key == "celtic_cross" then
        Sound.playSFX("cards_fast2")
        SCENE_MANAGER:switchScene(CelticCrossGameScene)
        return
    elseif option.key == "horoscope" then
        Sound.playSFX("cards_fast2")
        SCENE_MANAGER:switchScene(HoroscopeGameScene)
        return
    end
end


function SpreadSelectionScene:blinkButton(image)
    image:setImageDrawMode(gfx.kDrawModeInverted)

    pd.timer.performAfterDelay(69, function ()
        image:setImageDrawMode(gfx.kDrawModeCopy)
    end)

end

function SpreadSelectionScene:update()
    if pd.buttonJustPressed(pd.kButtonDown) then
        Sound.playABut()
        self.selectedRow = self.selectedRow + 1
        if self.selectedRow > #self.rowLabels then
            self.selectedRow = 1
        end
        self:updateSelectorPosition()
    elseif pd.buttonJustPressed(pd.kButtonUp) then
        Sound.playABut()
        self.selectedRow = self.selectedRow - 1
        if self.selectedRow < 1 then
            self.selectedRow = #self.rowLabels
        end
        self:updateSelectorPosition()
    end

    if self.selectedRow == 1 or self.selectedRow == 2 then
        if pd.buttonJustPressed(pd.kButtonRight) then
            self:blinkButton(self.selectorSpriteRight)
            Sound.playABut()
            if self.selectedRow == 1 then
                self:cycleSpreadOption(1)
            else
                self:cycleDeckOption(1)
            end
        elseif pd.buttonJustPressed(pd.kButtonLeft) then
            self:blinkButton(self.selectorSprite)
            Sound.playABut()
            if self.selectedRow == 1 then
                self:cycleSpreadOption(-1)
            else
                self:cycleDeckOption(-1)
            end
        end
    end

    if pd.buttonJustPressed(pd.kButtonA) then
        Sound.playABut()
        if self.selectedRow == 1 then
            self:blinkButton(self.selectorSpriteRight)
            self:blinkButton(self.selectorSprite)
            self:cycleSpreadOption(1)
        elseif self.selectedRow == 2 then
            self:blinkButton(self.selectorSpriteRight)
            self:blinkButton(self.selectorSprite)
            self:cycleDeckOption(1)
        else
            self:confirmSelection()
        end
    end

    if pd.buttonJustPressed(pd.kButtonB) then
        Sound.playSFX("b_button")
        SCENE_MANAGER:switchScene(AfterDialogueScene)
    end
end

function SpreadSelectionScene:deinit()
    if self.bgSprite then self.bgSprite:remove() self.bgSprite = nil end
    if self.selectorSprite then self.selectorSprite:remove() self.selectorSprite = nil end
    if self.selectorSpriteRight then self.selectorSpriteRight:remove() self.selectorSpriteRight = nil end
    if self.titleText then self.titleText:remove() self.titleText = nil end
    if self.spreadHeaderSprite then self.spreadHeaderSprite:remove() self.spreadHeaderSprite = nil end
    if self.spreadValueSprite then self.spreadValueSprite:remove() self.spreadValueSprite = nil end
    if self.deckHeaderSprite then self.deckHeaderSprite:remove() self.deckHeaderSprite = nil end
    if self.deckValueSprite then self.deckValueSprite:remove() self.deckValueSprite = nil end
    if self.goSprite then self.goSprite:remove() self.goSprite = nil end
    if self.noticeSprite then self.noticeSprite:remove() self.noticeSprite = nil end
    if self.noticeTimer then self.noticeTimer:remove() self.noticeTimer = nil end
end
