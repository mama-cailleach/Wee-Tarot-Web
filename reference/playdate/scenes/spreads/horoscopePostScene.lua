import "baseSpreadPostScene"

local HOROSCOPE_POST_CONFIG = {
    spreadKey = "horoscope",
    previewScale = 0.23,
    previewPositions = {
        { x = 60, y = 60 }, { x = 88, y = 60 }, { x = 116, y = 60 }, { x = 144, y = 60 }, { x = 172, y = 60 }, { x = 200, y = 60 },
        { x = 228, y = 60 }, { x = 256, y = 60 }, { x = 284, y = 60 }, { x = 312, y = 60 }, { x = 340, y = 60 }, { x = 368, y = 60 }
    }
}

class('HoroscopePostScene').extends(BaseSpreadPostScene)

function HoroscopePostScene:init(cardNames, cardNumbers, cardSuits, cardInverted, selectedCardIndex)
    HoroscopePostScene.super.init(self, HOROSCOPE_POST_CONFIG, cardNames, cardNumbers, cardSuits, cardInverted, selectedCardIndex)
end
