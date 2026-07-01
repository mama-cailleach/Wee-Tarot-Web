local pd <const> = playdate
local gfx <const> = pd.graphics

utils = {}

function createTextWithBackground(text, textColor, backgroundColor, paddingX, paddingY)
    local font = gfx.getSystemFont()
    local textWidth, textHeight = gfx.getTextSize(text, font)

    local backgroundWidth = textWidth + 2 * paddingX
    local backgroundHeight = textHeight + 1 * paddingY

    local image = gfx.image.new(backgroundWidth, backgroundHeight)

    gfx.pushContext(image)
        -- 1. Draw the background rectangle
        gfx.setColor(backgroundColor)
        gfx.fillRect(0, 0, backgroundWidth, backgroundHeight)

        -- 2. Draw the text on top
        gfx.drawText(text, paddingX, paddingY)
    gfx.popContext()

    return image
end

local function splitTextIntoParagraphs(text)
    local paragraphs = {}
    if type(text) ~= "string" or #text == 0 then
        return paragraphs
    end

    local startIndex = 1
    while true do
        local breakIndex = string.find(text, "\n", startIndex, true)
        if not breakIndex then
            table.insert(paragraphs, string.sub(text, startIndex))
            break
        end

        table.insert(paragraphs, string.sub(text, startIndex, breakIndex - 1))
        startIndex = breakIndex + 1
    end

    return paragraphs
end

local function wrapParagraphToWidth(paragraph, maxWidth, font)
    local wrappedLines = {}

    if paragraph == nil then
        return wrappedLines
    end

    if paragraph == "" then
        table.insert(wrappedLines, "")
        return wrappedLines
    end

    local currentLine = ""

    local function pushCurrentLine()
        if currentLine ~= "" then
            table.insert(wrappedLines, currentLine)
            currentLine = ""
        end
    end

    local function breakLongWord(word)
        local chunk = ""
        for index = 1, #word do
            local candidate = chunk .. word:sub(index, index)
            if gfx.getTextSize(candidate, font) <= maxWidth or chunk == "" then
                chunk = candidate
            else
                table.insert(wrappedLines, chunk)
                chunk = word:sub(index, index)
            end
        end

        if #chunk > 0 then
            if currentLine == "" then
                currentLine = chunk
            else
                local combined = currentLine .. " " .. chunk
                if gfx.getTextSize(combined, font) <= maxWidth then
                    currentLine = combined
                else
                    pushCurrentLine()
                    currentLine = chunk
                end
            end
        end
    end

    for word in string.gmatch(paragraph, "%S+") do
        if currentLine == "" then
            if gfx.getTextSize(word, font) <= maxWidth then
                currentLine = word
            else
                breakLongWord(word)
            end
        else
            local candidate = currentLine .. " " .. word
            if gfx.getTextSize(candidate, font) <= maxWidth then
                currentLine = candidate
            else
                pushCurrentLine()
                if gfx.getTextSize(word, font) <= maxWidth then
                    currentLine = word
                else
                    breakLongWord(word)
                end
            end
        end
    end

    pushCurrentLine()
    return wrappedLines
end

function utils.wrapTextToLines(text, maxWidth, font)
    local lines = {}
    for _, paragraph in ipairs(splitTextIntoParagraphs(text)) do
        local wrappedParagraph = wrapParagraphToWidth(paragraph, maxWidth, font)
        for _, line in ipairs(wrappedParagraph) do
            table.insert(lines, line)
        end
    end

    return lines
end

function utils.wrapTextIntoPages(text, maxWidth, maxRows, font)
    local lines = utils.wrapTextToLines(text, maxWidth, font)
    local pages = {}
    local currentPage = {}

    for _, line in ipairs(lines) do
        table.insert(currentPage, line)
        if #currentPage >= (maxRows or 3) then
            table.insert(pages, currentPage)
            currentPage = {}
        end
    end

    if #currentPage > 0 or #pages == 0 then
        table.insert(pages, currentPage)
    end

    return pages
end

function utils.wrapSectionsIntoPages(sections, maxWidth, maxRows, font)
    -- sections: array of { type=string, index=?, lines={...} }
    local pages = {}
    maxRows = maxRows or 3

    for _, section in ipairs(sections or {}) do
        local wrappedLines = {}
        for _, line in ipairs(section.lines or {}) do
            local linesForParagraph = utils.wrapTextToLines(line, maxWidth, font)
            for _, wl in ipairs(linesForParagraph) do
                table.insert(wrappedLines, wl)
            end
        end

        -- If section has no content, keep an empty page to preserve spacing
        if #wrappedLines == 0 then
            table.insert(pages, { "" })
        else
            local i = 1
            while i <= #wrappedLines do
                local page = {}
                for r = 1, maxRows do
                    if wrappedLines[i] then
                        table.insert(page, wrappedLines[i])
                        i = i + 1
                    else
                        break
                    end
                end
                table.insert(pages, page)
            end
        end
    end

    if #pages == 0 then
        table.insert(pages, { "" })
    end

    return pages
end


-- max string lenght for big scroll
-- "hello hello dear friends this is"


--[[
EXAMPLE FOR USING THIS
local myText = "Hello!"
local whiteColor = gfx.kColorWhite
local blackColor = gfx.kColorBlack
local paddingHorizontal = 5
local paddingVertical = 3

local textWithBackground = createTextWithBackground(myText, whiteColor, blackColor, paddingHorizontal, paddingVertical)

local textSprite = gfx.sprite.new(textWithBackground)
textSprite:moveTo(50, 50)
textSprite:add()

]]



-- type writer style boomerang text

function utils.PromptTextTypewriterBoomerang(text, x, y, delayPerChar, visibleTime, fadeOutTime)
    local width, height = gfx.getTextSize(text)
    if width == 0 or height == 0 then width, height = 10, 10 end

    local promptSprite = gfx.sprite.new()
    promptSprite:setCenter(0, 0)
    promptSprite:moveTo(x or 8, y or 8)
    promptSprite:add()

    local currentLength = 0
    local function updateText()
        currentLength += 1
        local shownText = string.sub(text, 1, currentLength)
        local textImage = gfx.image.new(width, height)
        gfx.pushContext(textImage)
            gfx.setColor(gfx.kColorWhite)
            gfx.drawTextAligned(shownText, 0, 0, kTextAlignment.left)
        gfx.popContext()
        promptSprite:setImage(textImage)
    end

    local typeTimer
    typeTimer = pd.timer.keyRepeatTimerWithDelay(delayPerChar or 40, delayPerChar or 40, function()
        if currentLength < #text then
            updateText()
        else
            typeTimer:remove()
            pd.timer.performAfterDelay(visibleTime or 1200, function()
                local removeLength = #text
                local function updateRemoveText()
                    removeLength -= 1
                    local shownText = string.sub(text, 1, removeLength)
                    local textImage = gfx.image.new(width, height)
                    gfx.pushContext(textImage)
                        gfx.setColor(gfx.kColorWhite)
                        gfx.drawTextAligned(shownText, 0, 0, kTextAlignment.left)
                    gfx.popContext()
                    promptSprite:setImage(textImage)
                end

                local removeTimer
                removeTimer = pd.timer.keyRepeatTimerWithDelay(fadeOutTime or delayPerChar or 40, fadeOutTime or delayPerChar or 40, function()
                    if removeLength > 0 then
                        updateRemoveText()
                    else
                        removeTimer:remove()
                        promptSprite:remove()
                    end
                end)
            end)
        end
    end)

    updateText()
    return promptSprite
end




function utils.PromptTextTypewriterOneWay(text, x, y, delayPerChar)
    local font = gfx.getSystemFont()
    local width, height = gfx.getTextSize(text, font)
    if width == 0 or height == 0 then width, height = 10, 10 end

    local promptSprite = gfx.sprite.new()
    promptSprite:setCenter(0, 0)
    promptSprite:moveTo(x or 8, y or 8)
    promptSprite:add()

    local currentLength = 0
    local function updateText()
        currentLength += 1
        local shownText = string.sub(text, 1, currentLength)
        local textImage = gfx.image.new(width, height)
        gfx.pushContext(textImage)
            gfx.setColor(gfx.kColorWhite)
            gfx.drawTextAligned(shownText, 0, 0, kTextAlignment.left)
        gfx.popContext()
        promptSprite:setImage(textImage)
    end

    local typeTimer -- declare first!
    typeTimer = pd.timer.keyRepeatTimerWithDelay(delayPerChar or 40, delayPerChar or 40, function()
        if currentLength < #text then
            updateText()
        else
            typeTimer:remove()
            -- After full text is shown, wait, then fade out (hide)
        end
    end)

    -- Show the first character immediately
    updateText()

    return promptSprite
end

return utils


--[[
example

call this at the top of the scene
local utilities = import "libraries/utils"

then use 
utilities.PromptTextTypewriterBoomerang("Hello!", 20, 4, 40, 2000)








]]