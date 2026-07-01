import "baseSpreadPostScene"

local PENTAGRAM_POST_CONFIG = {
    spreadKey = "pentagram",
    previewScale = 0.35,
    previewPositions = {
        { x = 110, y = 66 },
        { x = 155, y = 66 },
        { x = 200, y = 66 },
        { x = 245, y = 66 },
        { x = 290, y = 66 }
    }
}

class('PentagramPostScene').extends(BaseSpreadPostScene)

function PentagramPostScene:init(cardNames, cardNumbers, cardSuits, cardInverted, selectedCardIndex)
    PentagramPostScene.super.init(self, PENTAGRAM_POST_CONFIG, cardNames, cardNumbers, cardSuits, cardInverted, selectedCardIndex)
end
