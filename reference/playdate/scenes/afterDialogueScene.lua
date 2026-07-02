local pd <const> = playdate
local gfx <const> = playdate.graphics

-- Hub after a finished reading. Diary flush/prewarm runs in BufferScene before this.
class('AfterDialogueScene').extends(gfx.sprite)

function AfterDialogueScene:init()
    AfterDialogueScene.super.init(self)

    self.aButton = nil
    self.aButtonBlinkTimer = nil
    self.scrollBoxAnimatorIn = nil
    self.optionsTextOn = false
    self.dinahSprite = nil
    self.bgSprite = nil
    self.optionsSetupTimer = nil
    self.optionsStaggerTimers = {}

    -- Background + Dinah must exist before fade-out reveals this scene (empty = white flash).
    self.bgSprite = gfx.sprite.new(GameAssets.getDarkclothImage())
    self.bgSprite:moveTo(200, 120)
    self.bgSprite:add()

    self:setupDinahVisuals()

    -- Menu prompts are staggered after the fade (avoids a frame spike with diary flush timing).
    self.awaitingOptionsSetup = true

    self:add()
end

function AfterDialogueScene:setupDinahVisuals()
    if self.dinahSprite then
        return
    end

    self.imagetable = GameAssets.getDinahImagetable()
    self.dinahSprite = AnimatedSprite.new(self.imagetable)
    self:dinahSpriteLoad()
end

function AfterDialogueScene:dinahSpriteLoad()
    self.dinahSprite:addState("idle", 1, 6, {tickStep = 4, yoyo = true})
    self.dinahSprite:addState("transition", 1, 17, {tickStep = 1, loop = false})
    self.dinahSprite:moveTo(200, 120)
    self.dinahSprite:add()
    self.dinahSprite:playAnimation()
end

function AfterDialogueScene:clearOptionsStaggerTimers()
    if self.optionsSetupTimer then
        self.optionsSetupTimer:remove()
        self.optionsSetupTimer = nil
    end
    for _, timer in ipairs(self.optionsStaggerTimers) do
        if timer then
            timer:remove()
        end
    end
    self.optionsStaggerTimers = {}
end

function AfterDialogueScene:makeButtonSprite(letter, x, y, radius)
    local r = radius or 16
    local img = gfx.image.new(r * 2, r * 2)
    gfx.pushContext(img)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillCircleAtPoint(r, r, r)
        gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
        gfx.setLineWidth(2)
        gfx.drawCircleAtPoint(r, r, r)
        local font = gfx.getSystemFont()
        local w, h = gfx.getTextSize(letter, font)
        gfx.drawTextAligned(letter, r - w / 2, r - h / 2, kTextAlignment.left)
    gfx.popContext()
    local sprite = gfx.sprite.new(img)
    sprite:moveTo(x, y)
    sprite:add()
    return sprite
end


function AfterDialogueScene:makeInvertedButtonSprite(letter, x, y, radius)
    local r = radius or 16
    local img = gfx.image.new(r * 2, r * 2)
    gfx.pushContext(img)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillCircleAtPoint(r, r, r)
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        gfx.setLineWidth(2)
        gfx.drawCircleAtPoint(r, r, r)
        local font = gfx.getSystemFont()
        local w, h = gfx.getTextSize(letter, font)
        gfx.drawTextAligned(letter, r - w / 2, r - h / 2, kTextAlignment.left)
    gfx.popContext()
    local sprite = gfx.sprite.new(img)
    sprite:moveTo(x, y)
    sprite:add()
    return sprite
end

function AfterDialogueScene:optionsText()
    gfx.setImageDrawMode(gfx.kDrawModeInverted)
    if self.settingsText then self.settingsText:remove() end
    if self.interactText then self.interactText:remove() end
    if self.diaryText then self.diaryText:remove() end

    self:clearOptionsStaggerTimers()

    self.settingsText = utils.PromptTextTypewriterOneWay("menu", 35, 204, 80)

    table.insert(self.optionsStaggerTimers, pd.timer.performAfterDelay(34, function()
        self.interactText = utils.PromptTextTypewriterOneWay("reading", 282, 204, 80)
    end))

    table.insert(self.optionsStaggerTimers, pd.timer.performAfterDelay(68, function()
        self.diaryText = utils.PromptTextTypewriterOneWay("diary", 182, 204, 80)
        self.settingsButton = self:makeButtonSprite("ª", 16, 223, 13)
        self.interactButton = self:makeButtonSprite("A", 384, 223, 14)
        self.diaryButton = self:makeButtonSprite("B", 163, 223, 14)
    end))
end

function AfterDialogueScene:scheduleOptionsAfterFade()
    self:clearOptionsStaggerTimers()

    self.optionsSetupTimer = pd.timer.performAfterDelay(50, function()
        self.optionsSetupTimer = nil
        if not self.optionsTextOn then
            self:optionsText()
            self.optionsTextOn = true
        end
    end)
end

function AfterDialogueScene:loadGameAnimation()
    self.dinahSprite.states["transition"].onAnimationEndEvent = function ()
        SCENE_MANAGER:switchScene(SpreadSelectionScene)
    end
end



function AfterDialogueScene:blinkButton(button)
    button:setImageDrawMode(gfx.kDrawModeInverted)

    pd.timer.performAfterDelay(69, function ()
        button:setImageDrawMode(gfx.kDrawModeCopy)
    end)

end

function AfterDialogueScene:update()
    if self.awaitingOptionsSetup and not SCENE_MANAGER.transitioning then
        self.awaitingOptionsSetup = false
        self:scheduleOptionsAfterFade()
    end

    -- Hub controls (keep in sync with MenuScene:update when optionsTextOn).
    if self.optionsTextOn then
        if pd.buttonJustPressed(pd.kButtonUp) then
            self:blinkButton(self.settingsButton)
            Sound.playABut()
            Sound.playSFX("cards_fast2")
            SCENE_MANAGER:switchScene(SettingsScene)
        end
        if pd.buttonJustPressed(pd.kButtonA) then
            self:blinkButton(self.interactButton)
            self:loadGameAnimation()
            Sound.playSFX("cards_fast2")
            self.dinahSprite:changeState("transition")
        end
        if pd.buttonJustPressed(pd.kButtonB) then
            self:blinkButton(self.diaryButton)
            Sound.playABut()
            Sound.playSFX("cards_fast2")
            SCENE_MANAGER:switchScene(DiaryScene)
        end
    end
end

function AfterDialogueScene:deinit()
    self:clearOptionsStaggerTimers()

    if self.settingsText then self.settingsText:remove() self.settingsText = nil end
    if self.interactText then self.interactText:remove() self.interactText = nil end
    if self.diaryText then self.diaryText:remove() self.diaryText = nil end
    if self.settingsButton then self.settingsButton:remove() self.settingsButton = nil end
    if self.interactButton then self.interactButton:remove() self.interactButton = nil end
    if self.diaryButton then self.diaryButton:remove() self.diaryButton = nil end
    if self.dinahSprite then self.dinahSprite:remove() self.dinahSprite = nil end
    if self.bgSprite then self.bgSprite:remove() self.bgSprite = nil end
    if AfterDialogueScene.super and AfterDialogueScene.super.deinit then
        AfterDialogueScene.super.deinit(self)
    end
end
