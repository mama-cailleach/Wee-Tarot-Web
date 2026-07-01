import "data/cardDescriptions"
import "data/spreadReadingData"

OneCardReadingText = {}

local ALL_CARD_DATA = CARD_DATA

function OneCardReadingText.buildLines(cardName, isInverted)
    local cardInfo = ALL_CARD_DATA[cardName]
    if not cardInfo then
        print("Warning: No data found for card: " .. tostring(cardName) .. ". Using placeholder.")
        cardInfo = ALL_CARD_DATA["PlaceholderCard"]
    end

    local lines = {}

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

    local intro = "You pulled:\n" .. cardName .. (isInverted and "\nUpside down" or "")
    table.insert(lines, intro)

    local correspondenceData = cardInfo.correspondence
    if correspondenceData and #correspondenceData > 0 then
        for _, line in ipairs(correspondenceData) do
            table.insert(lines, line)
        end
    end

    local themes = SpreadReadingData.pickKeywords(cardName, isInverted == true, 3)

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

    if type(themes) == "table" and #themes > 0 then
        table.insert(lines, table.concat(themes, ", ") .. ".")
    end

    local fortuneLines
    if isInverted and cardInfo.reversed_fortune then
        fortuneLines = cardInfo.reversed_fortune
    else
        fortuneLines = cardInfo.upright_fortune
    end
    table.insert(lines, fortuneLines[math.random(1, #fortuneLines)])

    local lastLine = {
        "You can press *A* or *B* now darling, but I will not tell you what to do.",
        "*B* will show you what was. *A* moves you forward. Ghosts hate being summoned twice.",
        "Take a final peek with *B*.\nOr press *A* and let fate close the door.",
        "*B* reveals. *A* releases. You only haunt the past if you stay too long.",
        "One more look with *B*? To move on? *A* knows the way. The card will not follow.",
        "If your heart clings, press *B*. If it dares, *A*. The card forgets you soon.",
        "Press *B* for one last look. Press *A* to move on. The past doesn't wait, dearie.",
        "One last glance? Press *B*. Ready to let go? Press *A*. The veil doesn't open twice."
    }
    table.insert(lines, lastLine[math.random(1, #lastLine)])

    return lines, themes
end

return OneCardReadingText
