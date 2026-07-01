local pd <const> = playdate

ScreenShake = {}


function ScreenShake.screenShake(shakeTime, shakeMagnitude)
    -- Creating a value timer that goes from shakeMagnitude to 0, over
    -- the course of 'shakeTime' milliseconds
    local shakeTimer = playdate.timer.new(shakeTime, shakeMagnitude, 0)
    -- Every frame when the timer is active, we shake the screen
    shakeTimer.updateCallback = function(timer)
        -- Using the timer value, so the shaking magnitude
        -- gradually decreases over time
        local magnitude = math.floor(timer.value)
        local shakeX = math.random(-magnitude, magnitude)
        local shakeY = math.random(-magnitude, magnitude)
        playdate.display.setOffset(shakeX, shakeY)
    end
    -- Resetting the display offset at the end of the screen shake
    shakeTimer.timerEndedCallback = function()
        playdate.display.setOffset(0, 0)
    end
end



return ScreenShake


--[[ EXAMPLE 

function playdate.update()
    playdate.timer.updateTimers()
    if playdate.buttonJustPressed(playdate.kButtonA) then
        -- Shake the screen for 500ms, with the screen
        -- shaking around by about 5 pixels on each side
        screenShake(500, 5)
    end
    
    -- A circle to be able to view what the shaking looks like
    playdate.graphics.fillCircleAtPoint(200, 120, 10)
end
]]
