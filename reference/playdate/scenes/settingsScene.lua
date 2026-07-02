local pd <const> = playdate
local gfx <const> = playdate.graphics

class('SettingsScene').extends(gfx.sprite)


function SettingsScene:init()
    self.bgImage = gfx.image.new("images/bg/darkcloth")
    self.bgSprite = gfx.sprite.new(self.bgImage)
    self.bgSprite:moveTo(200,120)
    self.bgSprite:add()


    local img = gfx.image.new("images/bg/icon_tri_smol")
    self.spritewands = gfx.sprite.new(img)
    self.selectorX = 200
    self.spritewands:moveTo(self.selectorX, 70)
    self.spritewands:add()

    self.selectorSprite = self.spritewands
    
    gfx.setImageDrawMode(gfx.kDrawModeNXOR)

    self.titleText = gfx.sprite.spriteWithText("MENU", 400, 200, nil, nil, nil, kTextAlignment.center)  
    self.titleText:moveTo(200, 30)
    self.titleText:setScale(1)
    self.titleText:add()

    self.buttonX = 200
    self.topY = 70
    self.step = 35
    self.bottomY = self.topY + 3 * self.step
    self.backY = 212

    self:addButton("How To", self.buttonX, self.topY)
    self:addButton("Sounds", self.buttonX, self.topY + self.step)
    self:addButton("Credits", self.buttonX, self.bottomY - self.step)
    self:addButton("haha", self.buttonX, self.bottomY)
    self:addButton("Back", self.buttonX, self.backY)

    self.options = {
        {text = "How To", y = self.topY, key = "how_to"},
        {text = "Sounds", y = self.topY + self.step, key = "sound"},
        {text = "Credits", y = self.bottomY - self.step, key = "credits"},
        {text = "haha", y = self.bottomY, key = "hahahaha"},
        {text = "Back", y = self.backY, key = "back"}
    }
    self.selectedIndex = 1

    self:updateSelectorPosition()

    self:add()
end

function SettingsScene:updateSelectorPosition()
    local currentOption = self.options[self.selectedIndex]
    local textWidth = gfx.getTextSize(currentOption.text)
    local offset = 18
    self.selectorSprite:moveTo(self.selectorX - textWidth / 2 - offset, currentOption.y)
end

function SettingsScene:confirmSelection()
    local option = self.options[self.selectedIndex]

    if option.key == "how_to" then
        Sound.playSFX("cards_slow2")
        SCENE_MANAGER:switchScene(HowToMenuScene)
        return
    end

    if option.key == "sound" then
        Sound.playSFX("cards_slow2")
        SCENE_MANAGER:switchScene(SoundSettingsScene)
        return
    end

    if option.key == "credits" then
        Sound.playSFX("cards_slow2")
        SCENE_MANAGER:switchScene(CreditsScene)
        return
    end

    if option.key == "hahahaha" then
        Sound.playSFX("hahahaha")
        return
    end

    if option.key == "back" then
        Sound.playSFX("cards_slow2")
        SCENE_MANAGER:switchScene(AfterDialogueScene)
    end
end

function SettingsScene:update()
    if pd.buttonJustPressed(pd.kButtonDown) then
        Sound.playABut()
        self.selectedIndex = self.selectedIndex + 1
        if self.selectedIndex > #self.options then
            self.selectedIndex = 1
        end
        self:updateSelectorPosition()
    elseif pd.buttonJustPressed(pd.kButtonUp) then
        Sound.playABut()
        self.selectedIndex = self.selectedIndex - 1
        if self.selectedIndex < 1 then
            self.selectedIndex = #self.options
        end
        self:updateSelectorPosition()
    end

    if pd.buttonJustPressed(pd.kButtonA) then
        if self.options[self.selectedIndex].key ~= "hahahaha" then
            Sound.playABut()
        end
        self:confirmSelection()
    end

    if pd.buttonJustPressed(pd.kButtonB) then
        Sound.playSFX("b_button")
        Sound.playSFX("cards_slow")
        SCENE_MANAGER:switchScene(AfterDialogueScene)
    end
end

function SettingsScene:textOut()
    self.titleText:remove()
end

function SettingsScene:addButton(text, x, y)
    local buttonText = gfx.sprite.spriteWithText(text, 400, 200, nil, nil, nil, kTextAlignment.center)
    buttonText:moveTo(x, y)
    buttonText:add()
    self:add(buttonText)
    return buttonText
end
