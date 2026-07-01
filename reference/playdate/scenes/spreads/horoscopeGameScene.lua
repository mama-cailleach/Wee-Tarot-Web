import "baseSpreadGameScene"
import "horoscopePostScene"

local HOROSCOPE_CONFIG = {
    spreadKey = "horoscope",
    cardCount = 12,
    cardPositions = {
        { x = 50, y = 120 }, { x = 100, y = 160 }, { x = 150, y = 175 }, { x = 200, y = 190 }, { x = 250, y = 175 }, { x = 300, y = 160 },
        { x = 350, y = 120 }, { x = 300, y = 75 }, { x = 250, y = 60 }, { x = 200, y = 50 }, { x = 150, y = 60 }, { x = 100, y = 75 }
    },
    selectedCardPositions = {
        { x = 50, y = 120 }, { x = 100, y = 140 }, { x = 150, y = 150 }, { x = 200, y = 165 }, { x = 250, y = 150 }, { x = 300, y = 150 },
        { x = 350, y = 120 }, { x = 300, y = 95 }, { x = 250, y = 75 }, { x = 200, y = 75 }, { x = 150, y = 75 }, { x = 100, y = 95 }
    },
    zoomCardPositions = {
        { x = 70, y = 120 }, { x = 100, y = 120 }, { x = 150, y = 120 }, { x = 200, y = 120 }, { x = 250, y = 120 }, { x = 300, y = 120 },
        { x = 330, y = 120 }, { x = 300, y = 120 }, { x = 250, y = 120 }, { x = 200, y = 120 }, { x = 150, y = 120 }, { x = 100, y = 120 }
    },
    defaultScale = 0.65,
    selectedScale = 1.0,
    zoomScale = 1.725,
    revealDelay = 500,
    postSceneClass = HoroscopePostScene
}

class('HoroscopeGameScene').extends(BaseSpreadGameScene)

function HoroscopeGameScene:init(restoreState)
    HoroscopeGameScene.super.init(self, HOROSCOPE_CONFIG, restoreState)
end
