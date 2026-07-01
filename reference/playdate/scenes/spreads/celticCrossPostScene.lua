import "baseSpreadPostScene"

local CELTIC_CROSS_POST_CONFIG = {
    spreadKey = "celtic_cross",
    previewScale = 0.27,
    previewPositions = {
        { x = 74, y = 62 }, { x = 105, y = 62 }, { x = 136, y = 62 }, { x = 167, y = 62 }, { x = 198, y = 62 },
        { x = 229, y = 62 }, { x = 260, y = 62 }, { x = 291, y = 62 }, { x = 322, y = 62 }, { x = 353, y = 62 }
    }
}

class('CelticCrossPostScene').extends(BaseSpreadPostScene)

function CelticCrossPostScene:init(cardNames, cardNumbers, cardSuits, cardInverted, selectedCardIndex)
    CelticCrossPostScene.super.init(self, CELTIC_CROSS_POST_CONFIG, cardNames, cardNumbers, cardSuits, cardInverted, selectedCardIndex)
end
