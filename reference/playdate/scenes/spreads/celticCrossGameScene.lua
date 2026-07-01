import "baseSpreadGameScene"
import "celticCrossPostScene"

local CELTIC_CROSS_CONFIG = {
    spreadKey = "celtic_cross",
    cardCount = 10,
    cardPositions = {
        { x = 150, y = 120 }, { x = 150, y = 140 }, { x = 150, y = 190 }, { x = 80, y = 120 }, { x = 150, y = 50 },
        { x = 220, y = 120 }, { x = 300, y = 190 }, { x = 300, y = 140 }, { x = 300, y = 90 }, { x = 300, y = 50 }
    }, 
    selectedCardPositions = {
        { x = 150, y = 120 }, { x = 150, y = 140 }, { x = 150, y = 160 }, { x = 90, y = 120 }, { x = 150, y = 77 },
        { x = 220, y = 120 }, { x = 300, y = 160 }, { x = 300, y = 140 }, { x = 300, y = 90 }, { x = 300, y = 77 }
    }, 
    zoomCardPositions = {
        { x = 150, y = 120 }, { x = 150, y = 120 }, { x = 150, y = 120 }, { x = 90, y = 120 }, { x = 150, y = 120 },
        { x = 220, y = 120 }, { x = 300, y = 120 }, { x = 300, y = 120 }, { x = 300, y = 120 }, { x = 300, y = 120 }
    },
    cardRotations = {
        0, 90, 0, 0, 0,
        0, 0, 0, 0, 0
    },
    defaultScale = 0.65,
    selectedScale = 1.0,
    zoomScale = 1.725,
    revealDelay = 500,
    postSceneClass = CelticCrossPostScene
}

class('CelticCrossGameScene').extends(BaseSpreadGameScene)

function CelticCrossGameScene:init(restoreState)
    CelticCrossGameScene.super.init(self, CELTIC_CROSS_CONFIG, restoreState)
end
