import "baseSpreadGameScene"
import "pentagramPostScene"

local PENTAGRAM_CONFIG = {
    spreadKey = "pentagram",
    cardCount = 5,
    cardPositions = {
        { x = 200, y = 58 },
        { x = 80, y = 120 },
        { x = 150, y = 182 },
        { x = 250, y = 182 },
        { x = 320, y = 120 }
    },
    selectedCardPositions = {
        { x = 200, y = 80 },
        { x = 80, y = 120 },
        { x = 150, y = 160 },
        { x = 250, y = 160 },
        { x = 320, y = 120 }
    },
    zoomCardPositions = {
        { x = 200, y = 120 },
        { x = 80, y = 120 },
        { x = 150, y = 120 },
        { x = 250, y = 120 },
        { x = 320, y = 120 }
    },
    defaultScale = 0.75,
    selectedScale = 1.0,
    zoomScale = 1.725,
    revealDelay = 380,
    postSceneClass = PentagramPostScene
}

class('PentagramGameScene').extends(BaseSpreadGameScene)

function PentagramGameScene:init(restoreState)
    PentagramGameScene.super.init(self, PENTAGRAM_CONFIG, restoreState)
end

function PentagramGameScene:buildDrawPoolForSelection()
    self.selectedDeck = selectedDeck or "full"

    -- For alternate mode in Pentagram, use specific element mappings
    if self.selectedDeck == "alternate" then
        -- Pentagram element mapping:
        -- Position 1 (center/top): Major (Heart/Self)
        -- Position 2 (left): Swords (Air)
        -- Position 3 (bottom-left): Pentacles (Earth)
        -- Position 4 (bottom-right): Wands (Fire)
        -- Position 5 (right): Cups (Water)
        local elementMapping = {5, 3, 4, 2, 1} -- suit indices for each position
        
        local pool = {}
        for positionIndex, suitIndex in ipairs(elementMapping) do
            local selectedDeck = self.deck.allDecks[suitIndex]
            if selectedDeck and #selectedDeck > 0 then
                local cardNumber = math.random(1, #selectedDeck)
                table.insert(pool, {
                    name = selectedDeck[cardNumber],
                    number = cardNumber,
                    suit = suitIndex
                })
            end
        end
        return pool
    end

    -- For non-alternate modes, use the base class implementation
    return PentagramGameScene.super.buildDrawPoolForSelection(self)
end
