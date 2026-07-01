import "baseSpreadGameScene"
import "oneCardPostScene"

local ONE_CARD_CONFIG = {
    spreadKey = "one_card",
    cardCount = 1,
    cardPositions = {
        { x = 200, y = 120 }
    },
    selectedCardPositions = {
        { x = 200, y = 120 }
    },
    zoomCardPositions = {
        { x = 200, y = 120 }
    },
    defaultScale = 1.0,
    selectedScale = 1.0,
    zoomScale = 1.55,
    revealDelay = 500,
    nonSelectedDimAlpha = 0,
    enableSpinSlideShuffle = true,
    revealedDrawDelayMs = 1150,
    scaleAnimationTickStep = 1,
    useDarkclothPlacement = true,
    useRevealBackAnimation = true,
    useDiamondPlacementZone = true,
    useExplodeFinaleOnShuffleFinish = true,
    useLegacySingleCardDraw = true,
    postSceneClass = OneCardPostScene
}

class('OneCardGameScene').extends(BaseSpreadGameScene)

function OneCardGameScene:init(restoreState)
    OneCardGameScene.super.init(self, ONE_CARD_CONFIG, restoreState)
end
