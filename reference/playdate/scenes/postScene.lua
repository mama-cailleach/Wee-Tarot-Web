import "data/cardDescriptions"
import "data/save/diaryStore"
import "data/spreadReadingData"


local pd <const> = playdate
local gfx <const> = playdate.graphics

local ALL_CARD_DATA = CARD_DATA

-- Creates a shuffled COPY of the table, leaving the original data table untouched.
local function shuffle_table(tbl)
    local n = #tbl
    -- Create a shallow copy to shuffle, so the original data in ALL_CARD_DATA isn't modified
    local shuffled_copy = {}
    for i = 1, n do
        table.insert(shuffled_copy, tbl[i])
    end

    while n > 1 do
        local k = math.random(n) -- Pick a random element from 1 to n
        shuffled_copy[n], shuffled_copy[k] = shuffled_copy[k], shuffled_copy[n] -- 
        n = n - 1
    end
    return shuffled_copy
end

class('PostScene').extends(gfx.sprite)


function PostScene:init(cardName, cardNumber, cardSuit, isInverted)
    PostScene.super.init(self) -- IMPORTANT: Call the superclass init for sprite functionality

    self.card = cardName
    self.cardNumber = cardNumber
    self.cardSuit = cardSuit
    self.invert = isInverted

    -- --- Scene-Specific Variables ---
    self.imagetable = GameAssets.getDinahImagetable()
    self.dinahSprite = AnimatedSprite.new(self.imagetable)
    self.scrollBoxImg = GameAssets.getScrollBoxImage()
    self.scrollBoxSprite = gfx.sprite.new(self.scrollBoxImg)
    self.dinahText = {} -- This will be populated by addCardTextToDinah
    self.aButton = nil
    self.aButtonBlinkTimer = nil
    self.dinahScrollText = nil -- The text sprite itself
    self.canButton = false
    self.aPress = 0
    self.scrollBoxAnimatorIn = nil -- Will be created later
    self.scrollOffset = 0
    self.maxScroll = 0
    self.scrollBoxWidth = 310
    self.diaryEntrySaved = false

    -- --- TEXT ANIMATION LOOP PARAMETERS ---
    self.aButtonY = 220
    self.scrollBaseY = 170 -- scroll img base
    self.textBaseY = 182    -- The original, center Y position of the text
    self.textAmplitude = 3.7 -- How many pixels the text will move up and down from titleBaseY
    self.textSpeed = 2.5 -- Controls the speed/frequency of the oscillation.
    self.oscillationStartTime = nil -- Used to track the start time of the oscillation


    -- --- Call initial setup methods ---
    self:dinahSpriteLoad()

    -- Add card specific text, now as a method call
    self:addCardTextToDinah(self.card)
    self.scrollOffset = 0
    self.maxScroll = math.max(0, #self.dinahTextLines - 1)

    -- Set up the scroll box animator, and crucially, its callback
    self.scrollBoxAnimatorIn = gfx.animator.new(3000, 300, 170, pd.easingFunctions.outBack)
    self.scrollBoxSprite:moveTo(202, 300) -- Set initial position for animation
    self.scrollBoxSprite:add() -- Add it so it can be animated

    

    -- delay for text to come after animation
    self.scrollBoxTimer = pd.timer.performAfterDelay(3200, function ()
        self:onScrollBoxAnimationFinished()
        
    end)

    self:add()


end




-- Callback for scroll box animation finish
function PostScene:onScrollBoxAnimationFinished()
    self:showTextWindow()
    self.scrollBoxLoad = true -- Show the first text
    self.canButton = true
    self.oscillationStartTime = pd.getElapsedTime()
    -- Set the oscillation base to the final animator Y position for smooth transition
    if self.scrollBoxAnimatorIn then
        self.scrollBaseY = self.scrollBoxAnimatorIn:currentValue()
    end

end


function PostScene:dinahSpriteLoad()
    self.dinahSprite:addState("idle", 1, 6, {tickStep = 4, yoyo = true})
    self.dinahSprite:addState("transition", 1, 20, {tickStep = 1, loop = false})
    self.dinahSprite:moveTo(200,120)
    self.dinahSprite:add()
    self.dinahSprite:playAnimation()
end

function PostScene:showTextWindow()
    gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
    if self.dinahScrollText then
        self.dinahScrollText:remove()
        self.dinahScrollText = nil
    end
    local startLine = math.floor(self.scrollOffset) + 1
    local lines = {}
    local idx = startLine
    if self.dinahTextLines[idx] then
        table.insert(lines, self.dinahTextLines[idx])
    end
    local text = table.concat(lines, "\n")
    self.dinahScrollText = gfx.sprite.spriteWithText(text, self.scrollBoxWidth, 200, nil, nil, nil, kTextAlignment.center)
    self.dinahScrollText:moveTo(190, self.textBaseY)
    self.dinahScrollText:add()
end

function PostScene:buttonABlink()
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

function PostScene:removeAButton()
    if self.aButton then
        self.aButton:remove()
        self.aButton = nil
    end
    if self.aButtonBlinkTimer then
        self.aButtonBlinkTimer:remove()
        self.aButtonBlinkTimer = nil
    end
end


function PostScene:update()
     -- Animate scroll box in
    if self.scrollBoxAnimatorIn and not self.scrollBoxAnimatorIn:ended() then
        local scrollBoxY = self.scrollBoxAnimatorIn:currentValue()
        self.scrollBoxSprite:moveTo(202, scrollBoxY)
    end

    -- Always show A button when text is ready and not at options
    if self.canButton and not self.aButton then
        self:buttonABlink()
    end

    local oscillationOffset = 0
    if self.oscillationStartTime then
        local elapsed = pd.getElapsedTime()
        oscillationOffset = self.textAmplitude * math.sin((elapsed - self.oscillationStartTime) * self.textSpeed)
    end
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

    -- Advance text with A button
    if self.canButton and pd.buttonJustPressed(pd.kButtonA) then
        self.aPress += 1
        if self.scrollOffset < self.maxScroll then
            self.scrollOffset = self.scrollOffset + 1
            self:showTextWindow()
        else
            self:queueReadingToDiary()
            self.canButton = false
            self:removeAButton()
            if self.dinahScrollText then
                self.dinahScrollText:remove()
                self.dinahScrollText = nil
            end
            if self.scrollBoxSprite then
                self.scrollBoxSprite:remove()
            end
            Sound.playABut()
            Sound.prepareForBufferScene()
            SCENE_MANAGER:switchScene(BufferScene)
        end
    end

    if self.canButton and self.aPress >= 6 and pd.buttonJustPressed(pd.kButtonB) then
        Sound.playABut()
        self.canButton = false
        self:removeAButton()
        if self.dinahScrollText then 
            self.dinahScrollText:remove() 
            self.dinahScrollText = nil 
        end
        if self.scrollBoxSprite then 
            self.scrollBoxSprite:remove() 
        end
        local themes = self.diaryCardThemes
        if type(themes) ~= "table" or #themes == 0 then
            themes = SpreadReadingData.pickKeywords(self.card, self.invert == true, 3)
        end

        SCENE_MANAGER:switchScene(CardViewScene, self.card, self.cardNumber, self.cardSuit, self.invert, "one_card", {
            {
                name = self.card,
                number = self.cardNumber,
                suit = self.cardSuit,
                inverted = self.invert == true,
                position = 1,
                themes = themes
            }
        })
    end
end

function PostScene:queueReadingToDiary()
    if self.diaryEntrySaved then
        return
    end

    local themes = self.diaryCardThemes
    if type(themes) ~= "table" or #themes == 0 then
        themes = SpreadReadingData.pickKeywords(self.card, self.invert == true, 3)
    end

    DiaryStore.queueCompletedReading("one_card", {
        {
            name = self.card,
            number = self.cardNumber,
            suit = self.cardSuit,
            inverted = self.invert == true,
            position = 1,
            themes = themes
        }
    })
    self.diaryEntrySaved = true
end




-- populating the texts for the reading
function PostScene:addCardTextToDinah(cardName)
    local cardInfo = ALL_CARD_DATA[cardName]
    if not cardInfo then
        print("Warning: No data found for card: " .. cardName .. ". Using placeholder.")
        cardInfo = ALL_CARD_DATA["PlaceholderCard"]
    end

    local lines = {}

    -- 1. Card intro
    local introOptions = {
        "Hmmmm... Hmmmm...\n(squints at the card)\nVery interesting…",
        "(looks at you with a raised eyebrow)",
        "Shh... listen closely.\nNo, closer.",
        "Patience. The universe loves a dramatic pause.",
        "We may glimpse the dawn… or another dark night of the soul. Let's see.",
        "(sighs) Well, every card is a mirror. Know thyself…\nif you dare to look.",
        "Let me peer through the veil… it's a bit wrinkled today.",
        "Ah, this one… I remember its dance with fate.",
    }
    table.insert(lines, introOptions[math.random(1, #introOptions)])

    local intro = "You pulled:\n" .. cardName .. (self.invert and "\nUpside down" or "")
    table.insert(lines, intro)

    -- 2. Correspondence
    local correspondence_data = cardInfo.correspondence
    if correspondence_data and #correspondence_data > 0 then
        for _, line in ipairs(correspondence_data) do -- allows for multiple strings divided by line
            table.insert(lines, line)
        end
    end

    -- 3. Keywords
    local source_keywords_list
    if self.invert and cardInfo.reversed_keywords then
        source_keywords_list = cardInfo.reversed_keywords
    elseif cardInfo.upright_keywords then
        source_keywords_list = cardInfo.upright_keywords
    end

    local keywordIntroOptions = {
        "The spirits whisper... ",
        "The card's pulse summons forth: ",
        "The oracles of old murmur of: ",
        "From the sands of time, this card reveals: ",
        "This card hums with forgotten truths: ",
        "From the woven threads of fate, we find: ",
        "Here lies the essence unveiled: ",
        "Let these currents stir the soul: "
    }
    table.insert(lines, keywordIntroOptions[math.random(1, #keywordIntroOptions)])

    local final_keywords_to_display = {}
    local num_keywords_to_select = 3
    if source_keywords_list and #source_keywords_list > 0 then
        if #source_keywords_list <= num_keywords_to_select then
            final_keywords_to_display = source_keywords_list
        else
            local shuffled_list = shuffle_table(source_keywords_list)
            for i = 1, num_keywords_to_select do
                table.insert(final_keywords_to_display, shuffled_list[i])
                
            end
        end
        table.insert(lines, table.concat(final_keywords_to_display, ", ") .. ".")
        self.diaryCardThemes = final_keywords_to_display
    end

    -- 4. Fortune line
    local fortune_lines
    if self.invert and cardInfo.reversed_fortune then
        fortune_lines = cardInfo.reversed_fortune
    else
        fortune_lines = cardInfo.upright_fortune
    end
    table.insert(lines, fortune_lines[math.random(1, #fortune_lines)])


   -- 
   local lastLine =     {
    "You can press *A* or *B* now darling, but I will not tell you what to do.",
    "*B* will show you what was. *A* moves you forward. Ghosts hate being summoned twice.",
    "Take a final peek with *B*.\nOr press *A* and let fate close the door.",
    "*B* reveals. *A* releases. You only haunt the past if you stay too long.",
    "One more look with *B*? To move on? *A* knows the way. The card will not follow.",--
    "If your heart clings, press *B*. If it dares, *A*. The card forgets you soon.",--
    "Press *B* for one last look. Press *A* to move on. The past doesn't wait, dearie.",
    "One last glance? Press *B*. Ready to let go? Press *A*. The veil doesn't open twice."

    }
    table.insert(lines, lastLine[math.random(1, #lastLine)])

    -- Each entry is a "screen" of text for A button advance
    self.dinahTextLines = lines
    self.dinahTextBlock = table.concat(self.dinahTextLines, "\n")
end


function PostScene:deinit()
    if self.dinahSprite then self.dinahSprite:remove() self.dinahSprite = nil end
    if self.scrollBoxSprite then self.scrollBoxSprite:remove() self.scrollBoxSprite = nil end
    if self.dinahScrollText then self.dinahScrollText:remove() self.dinahScrollText = nil end
    if self.aButton then self.aButton:remove() self.aButton = nil end
    if self.aButtonBlinkTimer then self.aButtonBlinkTimer:remove() self.aButtonBlinkTimer = nil end
    if self.scrollBoxAnimatorIn then self.scrollBoxAnimatorIn = nil end
    if self.scrollBoxTimer then self.scrollBoxTimer:remove() self.scrollBoxTimer = nil end
    if self.crankSprite then self.crankSprite:remove() self.crankSprite = nil end
    self.imagetable = nil
    self.scrollBoxImg = nil
    self.dinahText = nil
    self.dinahTextLines = nil
    self.dinahTextBlock = nil
    if PostScene.super and PostScene.super.deinit then
        PostScene.super.deinit(self)
    end
end