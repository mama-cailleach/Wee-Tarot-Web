local pd <const> = playdate
local gfx <const> = pd.graphics

-- Precompute faded black images for the fade transition
local fadedRects = {}
local fadedRectsInitialized = false

local function initFadedRects()
    if fadedRectsInitialized then
        return
    end

    for i = 0, 1, 0.01 do
        local fadedImage = gfx.image.new(400, 240)
        gfx.pushContext(fadedImage)
            local filledRect = gfx.image.new(400, 240, gfx.kColorBlack)
            filledRect:drawFaded(0, 0, i, gfx.image.kDitherTypeBayer8x8)
        gfx.popContext()
        fadedRects[math.floor(i * 100)] = fadedImage
    end
    fadedRects[100] = gfx.image.new(400, 240, gfx.kColorBlack)
    fadedRectsInitialized = true
end


class('SceneManager').extends()

function SceneManager:init()
    self.transitionTime = 1000
    self.transitioning = false
end

function SceneManager:switchScene(scene, ...)
    if self.transitioning then
        return
    end

    self.transitioning = true
    self.newScene = scene
    self.sceneArgs = {...}
    self:startFadeTransition()
end

function SceneManager:loadNewScene()
    self:cleanupScene()
    self.currentScene = self.newScene(table.unpack(self.sceneArgs))
end

function SceneManager:cleanupScene()
        -- Call deinit on the current scene if it exists
    if self.currentScene and self.currentScene.deinit then
        self.currentScene:deinit()
    end
    -- Remove all sprites except the transition sprite instead of using gfx.sprite.removeAll()
    local allSprites = gfx.sprite.getAllSprites()
    for i = 1, #allSprites do
        local s = allSprites[i]
        if s ~= self.transitionSprite then
            s:remove()
        end
    end
    self:removeAllTimers()
    gfx.setDrawOffset(0, 0)
end

function SceneManager:startFadeTransition()
    local transitionSprite = self:createTransitionSprite()
    transitionSprite:setImage(self:getFadedImage(0))

    local fadeInTimer = pd.timer.new(self.transitionTime, 0, 1, pd.easingFunctions.inOutCubic)
    fadeInTimer.updateCallback = function(timer)
        transitionSprite:setImage(self:getFadedImage(timer.value))
    end
    fadeInTimer.timerEndedCallback = function()
        self:loadNewScene()
        
         -- Wait one frame to ensure the new scene is fully loaded before fading out
        pd.timer.performAfterDelay(1, function()
        -- Now fade out
        local fadeOutTimer = pd.timer.new(self.transitionTime, 1, 0, pd.easingFunctions.inOutCubic)
        fadeOutTimer.updateCallback = function(timer)
            transitionSprite:setImage(self:getFadedImage(timer.value))
        end
        
        fadeOutTimer.timerEndedCallback = function()
            self.transitioning = false
            transitionSprite:remove()
            -- Fix for sprite artifacts/smearing after transition
            local allSprites = gfx.sprite.getAllSprites()
            for i = 1, #allSprites do
                allSprites[i]:markDirty()
            end
        end
    end)
end
end

function SceneManager:getFadedImage(alpha)
    if not fadedRectsInitialized then
        initFadedRects()
    end

    return fadedRects[math.floor(alpha * 100)]
end

function SceneManager:createTransitionSprite()
    local filledRect = gfx.image.new(400, 240, gfx.kColorBlack)
    local transitionSprite = gfx.sprite.new(filledRect)
    transitionSprite:moveTo(200, 120)
    transitionSprite:setZIndex(10000)
    transitionSprite:setIgnoresDrawOffset(true)
    transitionSprite:add()
    self.transitionSprite = transitionSprite
    return transitionSprite
end

function SceneManager:removeAllTimers()
    local allTimers = pd.timer.allTimers()
    for _, timer in ipairs(allTimers) do
        timer:remove()
    end
end