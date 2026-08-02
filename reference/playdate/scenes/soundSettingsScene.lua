local pd <const> = playdate
local gfx <const> = playdate.graphics

class('SoundSettingsScene').extends(gfx.sprite)

local bgLabels = {"Music&Rain", "Music", "Rain"}
local sfxLabels = {"On", "Off"}

function SoundSettingsScene:init()
    SoundSettingsScene.super.init(self)

    self.bgSprite = gfx.sprite.new(GameAssets.getDarkclothImage())
    self.bgSprite:moveTo(200, 120)
    self.bgSprite:add()

    local selectorImage = GameAssets.getIconTriSmolImage()
    self.selectorSprite = gfx.sprite.new(selectorImage)
    self.selectorSprite:setRotation(270)
    self.selectorSprite:moveTo(120, 92)
    self.selectorSprite:add()

    self.titleText = gfx.sprite.spriteWithText("SOUNDS", 400, 200, nil, nil, nil, kTextAlignment.center)
    self.titleText:moveTo(200, 40)
    self.titleText:add()

    self.bgOptionIndex = Sound.getSoundMode()
    self.sfxOptionIndex = Sound.getSfxEnabled() and 1 or 2

    self.rowLabels = {"BG", "SFX", "Back"}
    self.rowY = {98, 138, 212}
    self.selectedRow = 1

    self.bgHeaderSprite = nil
    self.bgValueSprite = nil
    self.sfxHeaderSprite = nil
    self.sfxValueSprite = nil
    self.backSprite = nil

    self.titlePostion = 120
    self.optionPosition = 280

    self:createLayoutSprites()
    self:updateSelectorPosition()


    self:add()
end

function SoundSettingsScene:createLayoutSprites()
    self.bgHeaderSprite = gfx.sprite.spriteWithText("BG", 400, 40, nil, nil, nil, kTextAlignment.center)
    self.bgHeaderSprite:moveTo(self.titlePostion - 10, self.rowY[1])
    self.bgHeaderSprite:add()

    self.bgValueSprite = gfx.sprite.spriteWithText(bgLabels[self.bgOptionIndex], 400, 40, nil, nil, nil, kTextAlignment.center)
    if self.bgOptionIndex == 1 then
        self.bgValueSprite:moveTo(self.optionPosition - 20, self.rowY[1])
    else
        self.bgValueSprite:moveTo(self.optionPosition, self.rowY[1])
    end
    self.bgValueSprite:add()

    self.sfxHeaderSprite = gfx.sprite.spriteWithText("SFX", 400, 40, nil, nil, nil, kTextAlignment.center)
    self.sfxHeaderSprite:moveTo(self.titlePostion, self.rowY[2])
    self.sfxHeaderSprite:add()

    self.sfxValueSprite = gfx.sprite.spriteWithText(sfxLabels[self.sfxOptionIndex], 400, 40, nil, nil, nil, kTextAlignment.center)
    self.sfxValueSprite:moveTo(self.optionPosition, self.rowY[2])
    self.sfxValueSprite:add()

    self.backSprite = gfx.sprite.spriteWithText("Back", 400, 40, nil, nil, nil, kTextAlignment.center)
    self.backSprite:moveTo(200, self.rowY[3])
    self.backSprite:add()
end

function SoundSettingsScene:updateSelectorPosition()
    local rowLabel = self.rowLabels[self.selectedRow]
    local textWidth = gfx.getTextSize(rowLabel)
    local offset = 45
    local y = self.rowY[self.selectedRow] - 2

    if self.selectedRow == 3 then
        self.selectorSprite:setRotation(180)
        self.selectorSprite:moveTo(200, y - 25)
        --self.selectorSpriteRight:moveTo(200 + textWidth / 2 + offset, y)
    else
        self.selectorSprite:setRotation(270)
        if self.selectedRow == 2 then
            self.selectorSprite:moveTo(self.titlePostion + offset, y)
        else
            self.selectorSprite:moveTo(self.titlePostion - textWidth / 2 + offset, y)
        end
        -- self.selectorSpriteRight:moveTo(self.titlePostion + textWidth / 2 + (offset * 4), y)
    end
end

function SoundSettingsScene:updateBgValueSprite()
    if self.bgValueSprite then
        self.bgValueSprite:remove()
    end
    self.bgValueSprite = gfx.sprite.spriteWithText(bgLabels[self.bgOptionIndex], 400, 40, nil, nil, nil, kTextAlignment.center)
    if self.bgOptionIndex == 1 then
        self.bgValueSprite:moveTo(self.optionPosition - 20, self.rowY[1])
    else
        self.bgValueSprite:moveTo(self.optionPosition, self.rowY[1])
    end
    self.bgValueSprite:add()
end

function SoundSettingsScene:updateSfxValueSprite()
    if self.sfxValueSprite then
        self.sfxValueSprite:remove()
    end
    self.sfxValueSprite = gfx.sprite.spriteWithText(sfxLabels[self.sfxOptionIndex], 400, 40, nil, nil, nil, kTextAlignment.center)
    self.sfxValueSprite:moveTo(self.optionPosition, self.rowY[2])
    self.sfxValueSprite:add()
end

function SoundSettingsScene:applyBgMode()
    Sound.setSoundMode(self.bgOptionIndex)
    if self.bgOptionIndex ~= 2 then
        Sound.setAmbienceVolume(0.3)
        Sound.playAmbience()
    end
end

function SoundSettingsScene:applySfxMode()
    Sound.setSfxEnabled(self.sfxOptionIndex == 1)
end

function SoundSettingsScene:cycleBgOption(direction)
    local count = #bgLabels
    self.bgOptionIndex = ((self.bgOptionIndex - 1 + direction) % count) + 1
    self:updateBgValueSprite()
    self:applyBgMode()
end

function SoundSettingsScene:cycleSfxOption(direction)
    local count = #sfxLabels
    self.sfxOptionIndex = ((self.sfxOptionIndex - 1 + direction) % count) + 1
    self:updateSfxValueSprite()
    self:applySfxMode()
end

function SoundSettingsScene:goBack()
    Sound.playSFX("cards_slow2")
    SCENE_MANAGER:switchScene(SettingsScene)
end

function SoundSettingsScene:blinkButton(image)
    image:setImageDrawMode(gfx.kDrawModeInverted)

    pd.timer.performAfterDelay(69, function()
        image:setImageDrawMode(gfx.kDrawModeCopy)
    end)
end

function SoundSettingsScene:update()
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
            self:blinkButton(self.selectorSprite)
            Sound.playABut()
            if self.selectedRow == 1 then
                self:cycleBgOption(1)
            else
                self:cycleSfxOption(1)
            end
        elseif pd.buttonJustPressed(pd.kButtonLeft) then
            self:blinkButton(self.selectorSprite)
            Sound.playABut()
            if self.selectedRow == 1 then
                self:cycleBgOption(-1)
            else
                self:cycleSfxOption(-1)
            end
        end
    end

    if pd.buttonJustPressed(pd.kButtonA) then
        Sound.playABut()
        if self.selectedRow == 1 then
            self:blinkButton(self.selectorSprite)
            self:cycleBgOption(1)
        elseif self.selectedRow == 2 then
            self:blinkButton(self.selectorSprite)
            self:cycleSfxOption(1)
        else
            self:goBack()
        end
    end

    if pd.buttonJustPressed(pd.kButtonB) then
        Sound.playSFX("b_button")
        Sound.playSFX("cards_slow")
        self:goBack()
    end
end

function SoundSettingsScene:deinit()
    if self.bgSprite then self.bgSprite:remove() self.bgSprite = nil end
    if self.selectorSprite then self.selectorSprite:remove() self.selectorSprite = nil end
    if self.selectorSpriteRight then self.selectorSpriteRight:remove() self.selectorSpriteRight = nil end
    if self.titleText then self.titleText:remove() self.titleText = nil end
    if self.bgHeaderSprite then self.bgHeaderSprite:remove() self.bgHeaderSprite = nil end
    if self.bgValueSprite then self.bgValueSprite:remove() self.bgValueSprite = nil end
    if self.sfxHeaderSprite then self.sfxHeaderSprite:remove() self.sfxHeaderSprite = nil end
    if self.sfxValueSprite then self.sfxValueSprite:remove() self.sfxValueSprite = nil end
    if self.backSprite then self.backSprite:remove() self.backSprite = nil end
end
