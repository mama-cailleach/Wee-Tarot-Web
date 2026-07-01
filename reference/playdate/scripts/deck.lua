import "scripts/decks/allDecks"

class('Deck').extends()

local suitNameToIndex = {
    cups = 1,
    wands = 2,
    swords = 3,
    pentacles = 4,
    major = 5
}

function Deck:init()
    self.cupsDeck = cupsDeck
    self.wandsDeck = wandsDeck
    self.pentaclesDeck = pentaclesDeck
    self.swordsDeck = swordsDeck
    self.majorArcanaDeck = majorArcanaDeck

    self.allDecks = {
        self.cupsDeck,
        self.wandsDeck,
        self.swordsDeck,
        self.pentaclesDeck,
        self.majorArcanaDeck
    }

    -- Alternate deck mode state
    self.alternateDeckMode = false
    self.alternateAvailableSuits = {} -- Tracks which suits are available in current cycle
    self.alternateUsedCount = 0 -- Tracks how many cards have been drawn from current cycle
end

function Deck:drawFromDeck(deck, suitIndex)
    if not deck or #deck == 0 then return nil end
    local column = math.random(1, #deck)
    local cardDrawed = deck[column]
    local cardNumber = column
    local cardSuit = suitIndex
    return cardDrawed, cardNumber, cardSuit
end

function Deck:drawMajor()
    return self:drawFromDeck(self.majorArcanaDeck, suitNameToIndex.major)
end

function Deck:drawFromSuit(suitName)
    local suit = suitName and string.lower(suitName)
    local suitIndex = suitNameToIndex[suit]

    if suit == "cups" then
        return self:drawFromDeck(self.cupsDeck, suitIndex)
    elseif suit == "wands" then
        return self:drawFromDeck(self.wandsDeck, suitIndex)
    elseif suit == "swords" then
        return self:drawFromDeck(self.swordsDeck, suitIndex)
    elseif suit == "pentacles" then
        return self:drawFromDeck(self.pentaclesDeck, suitIndex)
    elseif suit == "major" then
        return self:drawFromDeck(self.majorArcanaDeck, suitIndex)
    end

    return nil
end

function Deck:drawMinorArcana()
    local minorDecks = {
        self.cupsDeck,
        self.wandsDeck,
        self.swordsDeck,
        self.pentaclesDeck
    }

    local row = math.random(1, #minorDecks)
    local selectedDeck = minorDecks[row]
    if #selectedDeck == 0 then return nil end
    local column = math.random(1, #selectedDeck)
    local cardDrawed = selectedDeck[column]
    local cardNumber = column
    local cardSuit = row
    return cardDrawed, cardNumber, cardSuit
end

function Deck:drawFullDeck()
    return self:drawRandomCard()
end

function Deck:drawRandomCard()
    local row = math.random(1, #self.allDecks)
    local selectedDeck = self.allDecks[row]
    if #selectedDeck == 0 then return nil end
    local column = math.random(1, #selectedDeck)
    local cardDrawed = selectedDeck[column]
    local cardNumber = column
    local cardSuit = row
    return cardDrawed, cardNumber, cardSuit
end

function Deck:initAlternateMode()
    self.alternateDeckMode = true
    self.alternateAvailableSuits = {1, 2, 3, 4, 5} -- cups, wands, swords, pentacles, major
    -- Shuffle the available suits so they're drawn in random order
    for i = #self.alternateAvailableSuits, 2, -1 do
        local j = math.random(i)
        self.alternateAvailableSuits[i], self.alternateAvailableSuits[j] = self.alternateAvailableSuits[j], self.alternateAvailableSuits[i]
    end
    self.alternateUsedCount = 0
end

function Deck:drawAlternate()
    if not self.alternateDeckMode then
        self:initAlternateMode()
    end

    -- If we've used all 5 suits, reset the cycle
    if self.alternateUsedCount >= 5 then
        self:initAlternateMode()
    end

    -- Get the next suit in the cycle
    self.alternateUsedCount = self.alternateUsedCount + 1
    local suitIndex = self.alternateAvailableSuits[self.alternateUsedCount]
    local selectedDeck = self.allDecks[suitIndex]

    if not selectedDeck or #selectedDeck == 0 then return nil end
    
    local column = math.random(1, #selectedDeck)
    local cardDrawed = selectedDeck[column]
    local cardNumber = column
    local cardSuit = suitIndex

    return cardDrawed, cardNumber, cardSuit
end

function Deck:drawAlternateFromSpecificSuit(suitIndex)
    if not self.alternateDeckMode then
        self:initAlternateMode()
    end

    local selectedDeck = self.allDecks[suitIndex]
    if not selectedDeck or #selectedDeck == 0 then return nil end
    
    local column = math.random(1, #selectedDeck)
    local cardDrawed = selectedDeck[column]
    local cardNumber = column
    local cardSuit = suitIndex

    return cardDrawed, cardNumber, cardSuit
end

function Deck:shuffle()
    -- Shuffle each deck in place
    for _, deck in ipairs(self.allDecks) do
        for i = #deck, 2, -1 do
            local j = math.random(i)
            deck[i], deck[j] = deck[j], deck[i]
        end
    end
end

function Deck:reset()
    -- Optionally re-populate and shuffle decks
    self:init()
    self:shuffle()
    self.alternateDeckMode = false
    self.alternateAvailableSuits = {}
    self.alternateUsedCount = 0
end

function Deck:isEmpty()
    for _, deck in ipairs(self.allDecks) do
        if #deck > 0 then return false end
    end
    return true
end


return Deck