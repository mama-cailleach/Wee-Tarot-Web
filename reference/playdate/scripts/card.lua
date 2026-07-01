local pd <const> = playdate
local gfx <const> = pd.graphics

class("Card").extends(gfx.sprite)

local suitFolders = {"cups", "wands", "swords", "pentacles", "majorArcana"}

function Card.getSuitFolder(cardSuit)
    return suitFolders[cardSuit]
end

function Card.getImagePath(cardNumber, cardSuit, zoomed)
    local suitFolder = Card.getSuitFolder(cardSuit)
    if not suitFolder or cardNumber == nil then
        return nil
    end

    local imagePath = "images/" .. suitFolder .. "/" .. tostring(cardNumber)
    if zoomed then
        imagePath = imagePath .. "_zoom"
    end

    return imagePath
end

function Card.getZoomPath(imagePath)
    if not imagePath then
        return nil
    end

    return imagePath .. "_zoom"
end

function Card.loadImageWithZoomFallback(imagePath, zoomed)
    if not imagePath then
        return nil
    end

    if zoomed then
        local zoomImage = gfx.image.new(Card.getZoomPath(imagePath))
        if zoomImage then
            return zoomImage
        end
    end

    return gfx.image.new(imagePath)
end

function Card:init(cardNumber, cardSuit)
    self.cardNumber = cardNumber
    self.cardSuit = cardSuit
    self.baseImagePath = Card.getImagePath(cardNumber, cardSuit, false)
    self.zoomImagePath = Card.getImagePath(cardNumber, cardSuit, true)
    self.baseImage = Card.loadImageWithZoomFallback(self.baseImagePath, false)
    self.zoomImage = nil
    self.zoomed = false

    self:setImage(self.baseImage)
    self:moveTo(200, 120)
    self:setScale(1)
    self.inverted = false
    self:upsideDown(self)
    --self:setZIndex(100)
    self:add()
end

function Card:getZoomImage()
    if self.zoomImage then
        return self.zoomImage
    end

    if not self.zoomImagePath then
        return self.baseImage
    end

    if self.zoomImagePath then
        self.zoomImage = gfx.image.new(self.zoomImagePath)
    else
        self.zoomImage = nil
    end
    if self.zoomImage then
        return self.zoomImage
    end

    return self.baseImage
end

function Card:setZoomed(zoomed)
    self.zoomed = zoomed and true or false

    local targetImage = self.zoomed and self:getZoomImage() or self.baseImage
    if targetImage then
        self:setImage(targetImage)
    end

    return targetImage
end

function Card:update()

end


function Card:upsideDown(drawed)
    local chance = math.random()
    if chance >= 0.51 then
        drawed:setRotation(180)
        self.inverted = true
    end
end