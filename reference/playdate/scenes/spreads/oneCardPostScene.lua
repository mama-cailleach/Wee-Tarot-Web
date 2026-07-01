import "baseSpreadPostScene"
import "data/oneCardReadingText"

local pd <const> = playdate
local gfx <const> = pd.graphics

local ONE_CARD_POST_CONFIG = {
    spreadKey = "one_card",
    scrollRevealDelayMs = 3200,
    enableCardPreviews = false,
    previewScale = 0.55,
    previewPositions = {
        { x = 200, y = 74 }
    }
}

class('OneCardPostScene').extends(BaseSpreadPostScene)

function OneCardPostScene:init(cardNames, cardNumbers, cardSuits, cardInverted, selectedCardIndex)
    OneCardPostScene.super.init(self, ONE_CARD_POST_CONFIG, cardNames, cardNumbers, cardSuits, cardInverted, selectedCardIndex)

    self.dinahTextLines = nil
    self.scrollOffset = 0
    self.maxScroll = 0
    self.aPress = 0
    self.scrollBoxLoad = false
end

function OneCardPostScene:ensureReadingTextBuilt()
    if self.dinahTextLines then
        return
    end

    local cardName = self.cardNames[1]
    local isInverted = self.cardInverted[1] == true
    local themes
    self.dinahTextLines, themes = OneCardReadingText.buildLines(cardName, isInverted)
    if type(themes) == "table" and #themes > 0 then
        self.cardThemes = { themes }
    end
    self.maxScroll = math.max(0, #self.dinahTextLines - 1)
end

function OneCardPostScene:ensureCardThemes()
    if self.cardThemes then
        return
    end

    self:ensureReadingTextBuilt()

    if not self.cardThemes then
        OneCardPostScene.super.ensureCardThemes(self)
    end
end

function OneCardPostScene:onScrollBoxAnimationFinished()
    self:ensureReadingTextBuilt()
    self.scrollBoxLoad = true
    self:showTextWindow()
    self.canButton = true
    self.oscillationStartTime = pd.getElapsedTime()
end

function OneCardPostScene:showTextWindow()
    gfx.setImageDrawMode(gfx.kDrawModeFillBlack)

    if self.textSprite then
        self.textSprite:remove()
        self.textSprite = nil
    end

    local startLine = math.floor(self.scrollOffset) + 1
    local lines = {}
    if self.dinahTextLines and self.dinahTextLines[startLine] then
        table.insert(lines, self.dinahTextLines[startLine])
    end

    local text = table.concat(lines, "\n")
    self.textSprite = gfx.sprite.spriteWithText(text, self.textBoxWidth, 200, nil, nil, nil, kTextAlignment.center)
    self.textSprite:moveTo(190, self.textBaseY)
    self.textSprite:add()
end

function OneCardPostScene:finishReading()
    if self.textSprite then
        self.textSprite:remove()
        self.textSprite = nil
    end
    if self.scrollBoxSprite then
        self.scrollBoxSprite:remove()
        self.scrollBoxSprite = nil
    end
    OneCardPostScene.super.finishReading(self)
end

function OneCardPostScene:goBackToSpreadView()
    if self.textSprite then
        self.textSprite:remove()
        self.textSprite = nil
    end
    if self.scrollBoxSprite then
        self.scrollBoxSprite:remove()
        self.scrollBoxSprite = nil
    end

    OneCardPostScene.super.goBackToSpreadView(self)
end

function OneCardPostScene:update()
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

    if self.scrollBoxLoad then
        if self.textSprite then
            self.textSprite:moveTo(self.textSprite.x, self.textBaseY + offset)
        end
        if self.scrollBoxSprite then
            self.scrollBoxSprite:moveTo(self.scrollBoxSprite.x, 170 + offset)
        end
        if self.aButton then
            self.aButton:moveTo(self.aButton.x, self.aButtonY + offset)
        end
    end

    if self.canButton and pd.buttonJustPressed(pd.kButtonA) then
        self.aPress += 1

        if self.scrollOffset < self.maxScroll then
            self.scrollOffset += 1
            self:showTextWindow()
        else
            Sound.playABut()
            self:finishReading()
        end
    end

    if self.canButton and self.aPress >= 6 and pd.buttonJustPressed(pd.kButtonB) then
        Sound.playABut()
        self:goBackToSpreadView()
    end
end

function OneCardPostScene:deinit()
    self.dinahTextLines = nil
    OneCardPostScene.super.deinit(self)
end
