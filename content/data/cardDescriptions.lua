
import "data/cardDescriptionsMajor"
import "data/cardDescriptionsWands"
import "data/cardDescriptionsCups"
import "data/cardDescriptionsSwords"
import "data/cardDescriptionsPentacles"

CARD_DATA = {}


-- Add major arcana to CARD_DATA
for k, v in pairs(CARD_DATA_MAJOR) do CARD_DATA[k] = v end

-- Merge all suit tables into CARD_DATA
for k, v in pairs(CARD_DATA_WANDS) do CARD_DATA[k] = v end
for k, v in pairs(CARD_DATA_CUPS) do CARD_DATA[k] = v end
for k, v in pairs(CARD_DATA_SWORDS) do CARD_DATA[k] = v end
for k, v in pairs(CARD_DATA_PENTACLES) do CARD_DATA[k] = v end
