import "baseSpreadGameScene"
import "threeCardPostScene"

local THREE_CARD_CONFIG = {
    spreadKey = "three_card",
    cardCount = 3,
    cardPositions = {
        { x = 100, y = 120 },
        { x = 200, y = 120 },
        { x = 300, y = 120 }
    },
    selectedCardPositions = {
        { x = 100, y = 120 },
        { x = 200, y = 120 },
        { x = 300, y = 120 }
    },
    zoomCardPositions = {
        { x = 100, y = 120 },
        { x = 200, y = 120 },
        { x = 300, y = 120 }
    },
    defaultScale = 0.9,
    selectedScale = 1.0,
    zoomScale = 1.725,
    revealDelay = 450,
    nonSelectedDimAlpha = 0.2,
    postSceneClass = ThreeCardPostScene
}

class('ThreeCardGameScene').extends(BaseSpreadGameScene)

function ThreeCardGameScene:init(restoreState)
    ThreeCardGameScene.super.init(self, THREE_CARD_CONFIG, restoreState)
end
