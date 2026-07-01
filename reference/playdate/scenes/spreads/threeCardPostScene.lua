import "baseSpreadPostScene"

local THREE_CARD_POST_CONFIG = {
    spreadKey = "three_card",
    previewScale = 0.42,
    previewPositions = {
        { x = 130, y = 74 },
        { x = 200, y = 74 },
        { x = 270, y = 74 }
    }
}

class('ThreeCardPostScene').extends(BaseSpreadPostScene)

function ThreeCardPostScene:init(cardNames, cardNumbers, cardSuits, cardInverted, selectedCardIndex)
    ThreeCardPostScene.super.init(self, THREE_CARD_POST_CONFIG, cardNames, cardNumbers, cardSuits, cardInverted, selectedCardIndex)
end
