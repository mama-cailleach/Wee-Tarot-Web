local pd <const> = playdate
local gfx <const> = playdate.graphics

-- First-time hub after title: scroll intro, then same menu hub as AfterDialogueScene (optionsTextOn).
class('MenuScene').extends(gfx.sprite)

local MAX_VISIBLE_LINES = 1

function MenuScene:init()
    MenuScene.super.init(self)
    Sound.setAmbienceVolume(0.3)

    -- scene variables
    self.imagetable = gfx.imagetable.new("images/bg/dinahBG-table-400-266")
    self.dinahSprite = AnimatedSprite.new(self.imagetable)
    self.scrollBoxImg = gfx.image.new("images/textScroll/scroll1b")
    self.scrollBoxSprite = gfx.sprite.new(self.scrollBoxImg)
    self.dinahLines = {}
    self.scrollOffset = 0
    self.maxScroll = 0
    self.dinahScrollText = nil
    self.aButton = nil
    self.aButtonBlinkTimer = nil
    self.scrollBoxAnimatorIn = nil 
    self.scrollBoxY = nil
    self.scrollBoxLoad = false
    self.optionsTextOn = false
    self.optionsSetupTimer = nil
    self.optionsStaggerTimers = {}

    -- --- TEXT ANIMATION LOOP PARAMETERS ---
    self.aButtonY = 220
    self.scrollBaseY = 170 -- scroll img base
    self.textBaseY = 182    -- The original, center Y position of the text
    self.textAmplitude = 3.7 -- How many pixels the text will move up and down from titleBaseY
    self.textSpeed = 2.5 -- Controls the speed/frequency of the oscillation.
    self.oscillationStartTime = nil -- Used to track the start time of the oscillation

    -- scene set up methods
    self:dinahTexts()
    self:dinahSpriteLoad()
    self:scrollBoxCreate()

    self:add()
end

function MenuScene:dinahTexts()
    -- Store all lines in a flat array
    local texts = {
        "...",
        "Welcome to my humble abode, I've been expecting you.",
        "Yes, yes... I can see... Your future is bright.\nCare for a reading, darling?",
        "Please...\nHave a seat...\nDon't be scared...",
        "I speak only what I see, but to find more meaning in the cards is up to you."
    }
    for _, t in ipairs(texts) do
        for line in t:gmatch("[^\n]+") do
            table.insert(self.dinahLines, line)
        end
    end
    self.scrollOffset = 0 -- float, for smooth scrolling
    self.maxScroll = math.max(0, #self.dinahLines - MAX_VISIBLE_LINES)
end

function MenuScene:showTextWindow()
    if self.dinahScrollText then
        self.dinahScrollText:remove()
        self.dinahScrollText = nil
    end
    local startLine = math.floor(self.scrollOffset) + 1
    local lines = {}
    for i = 0, MAX_VISIBLE_LINES - 1 do
        local idx = startLine + i
        if self.dinahLines[idx] then
            table.insert(lines, self.dinahLines[idx])
        end
    end
    local text = table.concat(lines, "\n")
    self.dinahScrollText = gfx.sprite.spriteWithText(text, 310, 200, nil, nil, nil, kTextAlignment.center)
    self.dinahScrollText:moveTo(190, self.textBaseY)
    self.dinahScrollText:add()
end

function MenuScene:buttonABlink()
    if self.aButton then return end
    gfx.setImageDrawMode(gfx.kDrawModeInverted)
    self.aButton = gfx.sprite.spriteWithText("A", 40, 40, nil, nil, nil, kTextAlignment.center)
    self.aButton:moveTo(360, 220)
    self.aButton:add()
    self.aButtonBlinkTimer = pd.timer.new(800, function()
        if self.aButton then self.aButton:setVisible(not self.aButton:isVisible()) end
    end)
    self.aButtonBlinkTimer.repeats = true
    gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
end

function MenuScene:removeAButton()
    if self.aButton then
        self.aButton:remove()
        self.aButton = nil
    end
    if self.aButtonBlinkTimer then
        self.aButtonBlinkTimer:remove()
        self.aButtonBlinkTimer = nil
    end
end

function MenuScene:dinahSpriteLoad()
    self.dinahSprite:addState("idle", 1, 6, {tickStep = 4, yoyo = true})
    self.dinahSprite:addState("transition", 1, 17, {tickStep = 1, loop = false})
    self.dinahSprite:moveTo(200,120)
    self.dinahSprite:add()
    self.dinahSprite:playAnimation()
end

function MenuScene:scrollBoxCreate()
    self.scrollBoxAnimatorIn = gfx.animator.new(3000, 300, 170, pd.easingFunctions.outBack)
    self.scrollBoxSprite:moveTo(202, 300)
    self.scrollBoxSprite:add()
    pd.timer.performAfterDelay(3200, function ()
        self:onScrollBoxAnimationFinished()
    end)
end

function MenuScene:onScrollBoxAnimationFinished()
    self:showTextWindow()
    self.scrollBoxLoad = true -- Show the first text
    self.oscillationStartTime = pd.getElapsedTime()
    -- Set the oscillation base to the final animator Y position for smooth transition
    if self.scrollBoxAnimatorIn then
        self.scrollBaseY = self.scrollBoxAnimatorIn:currentValue()
    end
end

function MenuScene:clearOptionsStaggerTimers()
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

function MenuScene:makeButtonSprite(letter, x, y, radius)
    local r = radius or 16
    local img = gfx.image.new(r*2, r*2)
    gfx.pushContext(img)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillCircleAtPoint(r, r, r)
        gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
        gfx.setLineWidth(2)
        gfx.drawCircleAtPoint(r, r, r)
        local font = gfx.getSystemFont()
        local w, h = gfx.getTextSize(letter, font)
        gfx.drawTextAligned(letter, r - w/2, r - h/2, kTextAlignment.left)
    gfx.popContext()
    local sprite = gfx.sprite.new(img)
    sprite:moveTo(x, y)
    sprite:add()
    return sprite
end

function MenuScene:makeInvertedButtonSprite(letter, x, y, radius)
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

function MenuScene:optionsText()
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

function MenuScene:loadGameAnimation()
    self.dinahSprite.states["transition"].onAnimationEndEvent = function ()
        SCENE_MANAGER:switchScene(SpreadSelectionScene)
    end
end

function MenuScene:blinkButton(button)
    button:setImageDrawMode(gfx.kDrawModeInverted)

    pd.timer.performAfterDelay(69, function ()
        button:setImageDrawMode(gfx.kDrawModeCopy)
    end)
end

function MenuScene:update()
    -- Animate scroll box in
    if self.scrollBoxAnimatorIn and not self.scrollBoxAnimatorIn:ended() then
        self.scrollBoxY = self.scrollBoxAnimatorIn:currentValue()
        self.scrollBoxSprite:moveTo(202, self.scrollBoxY)
    end

    local elapsed = pd.getElapsedTime()
    local oscillationOffset = self.textAmplitude * math.sin((elapsed - (self.oscillationStartTime or 0)) * self.textSpeed)
    local textNewY = self.textBaseY + oscillationOffset + 0.2
    local scrollNewY = 170 + oscillationOffset + 0.2
    local abuttonNewY = self.aButtonY + oscillationOffset + 0.2
    if self.scrollBoxLoad then
        if self.dinahScrollText then
            self.dinahScrollText:moveTo(self.dinahScrollText.x, textNewY)
        end
        if self.scrollBoxSprite then
            self.scrollBoxSprite:moveTo(self.scrollBoxSprite.x, scrollNewY)
        end
        if self.aButton then
            self.aButton:moveTo(self.aButton.x, abuttonNewY)
        end
    end

    -- Only allow A to advance text (crank logic commented out)
    if self.scrollBoxLoad and not self.optionsTextOn then
        -- Always show A button
        if not self.aButton then self:buttonABlink() end
        -- Allow A to proceed to next text
        if pd.buttonJustPressed(pd.kButtonA) then
            if self.scrollOffset < self.maxScroll then
                self.scrollOffset = self.scrollOffset + 1
                self:showTextWindow()
            else
                -- At end, proceed to options
                if self.dinahScrollText then self.dinahScrollText:remove() self.dinahScrollText = nil end
                if self.scrollBoxSprite then self.scrollBoxSprite:remove() end
                self:removeAButton()
                self:optionsText()
                self.optionsTextOn = true
            end
        end
    -- DON'T CHANGE THIS ELSEIF EVER! IT'S HOW IT WORKS ON THIS SCENE!!!!!!!!!!!!
    elseif self.optionsTextOn then
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


function MenuScene:deinit()
    self:clearOptionsStaggerTimers()

    if self.settingsText then self.settingsText:remove() self.settingsText = nil end
    if self.interactText then self.interactText:remove() self.interactText = nil end
    if self.diaryText then self.diaryText:remove() self.diaryText = nil end
    if self.settingsButton then self.settingsButton:remove() self.settingsButton = nil end
    if self.interactButton then self.interactButton:remove() self.interactButton = nil end
    if self.diaryButton then self.diaryButton:remove() self.diaryButton = nil end
    if self.dinahScrollText then self.dinahScrollText:remove() self.dinahScrollText = nil end
    if self.scrollBoxSprite then self.scrollBoxSprite:remove() self.scrollBoxSprite = nil end
    self:removeAButton()
    if self.dinahSprite then self.dinahSprite:remove() self.dinahSprite = nil end
    if MenuScene.super and MenuScene.super.deinit then
        MenuScene.super.deinit(self)
    end
end